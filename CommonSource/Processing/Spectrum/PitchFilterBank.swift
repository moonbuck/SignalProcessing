//
//  PitchFilterbank.swift
//  SignalProcessing
//
//  Created by Jason Cardwell on 10/2/17.
//  Copyright © 2017 Moondeer Studios. All rights reserved.
//
import Foundation
import Accelerate
import AVFoundation

extension Array {

  fileprivate subscript<R>(position: R) -> Element where R:RawRepresentable, R.RawValue == Int {
    get {
      return self[position.rawValue]
    }
    set {
      self[position.rawValue] = newValue
    }
  }

  fileprivate subscript<R>(bounds: CountableRange<R>) -> ArraySlice<Element>
    where R:RawRepresentable, R.RawValue == Int
  {
    return self[bounds.lowerBound.rawValue..<bounds.upperBound.rawValue]
  }

}

/// A multirate filterbank ported from the Tipic plugin by Queen Mary, University of London.
public final class PitchFilterbank {

  /// The range of pitches for which there is a corresponding filter for energy extraction.
  public let pitchRange: CountableRange<Pitch> = Pitch.pianoKeys

  /// The frame rate of extracted pitch features in Hz.
  public static let outputSampleRate = 10.0

  /// The expected sample rate for incoming signals.
  public let sampleRate: SampleRate

  /// The frequency to use as concert pitch.
  public let tuning: Frequency

  /// Queue used to ensure concurrency for iterative blocks.
  private let global = DispatchQueue.global()

  /// Queue used to synchronize access to resources.
  private let queue = DispatchQueue(label: "com.moondeerstudios.SignalProcessing.PitchFilterbank")

  /// The total number of filters for extracting pitch energies. Equal to `pitchRange.count`.
  private let filterCount = 88

  /// The input rate fed to the resamplers that accounts for any tuning adjustments.
  private let effectiveInputRate: Int

  /// `sampleRate / effectiveInputRate`.
  private let tuningRatio: Float64

  /// The filters applied to processed signals to extract pitch energies.
  private var filters: [IIRFilter] = []

  /// The objects used to resample signals being processed into the necessary sample rates.
  private let resamplers: [SampleRate:Resampler]

  /// The signal resampled for various rates by `resamplers`.
  private var resampled: [SampleRate:[Float64]] = [:]

  /// Whether the invocation to process a signal supplied the buffer with the necessary rates.
  private var multirateSignalBufferProvided = false

  /// Holds per pitch delays not yet accounted for in `energies`.
  private var toCompensate = Array<Int>(repeating: 0, count: 128)

  /// A filtered signal for each pitch in `pitchRange`. For each pitch it's corresponding
  /// buffer in `resampled` is filtered by its corresponding filter from `filters`.
  private var filtered = Array<[Float64]>(repeating: [], count: 128)

  /// The pitch energies calculated from `filtered`.
  private var energies = Array<[Float64]>(repeating: [], count: 128)

  /// The current block number for new frames.
  private var blockNo = 0

  /// Initializing with an incoming sample rate and tuning frequency.
  ///
  /// - Parameters:
  ///   - sampleRate: The sample rate of input signals before being resampeld by the filterbank.
  ///   - tuning: The frequency to serve as a reference for input signals.
  public init(sampleRate: SampleRate, tuning: Frequency) {

    // Initialize the sample rate and tuning frequency properties.
    self.sampleRate = sampleRate
    self.tuning = tuning

    // Calculate the effective input rate for the resamplers.
    effectiveInputRate = Int((Float64(sampleRate.rawValue * 440) / tuning.rawValue).rounded())

    // Initialize the tuning ratio for the expected and effective sample rates.
    tuningRatio = Float64(sampleRate.rawValue) / Float64(effectiveInputRate)

    // Initialize `resamplers` for the necessary rates.
    resamplers = [
      441:   Resampler(sourceRate: effectiveInputRate, targetRate: 441,   snr: 50, bandwidth: 0.05),
      882:   Resampler(sourceRate: effectiveInputRate, targetRate: 882,   snr: 50, bandwidth: 0.05),
      4410:  Resampler(sourceRate: effectiveInputRate, targetRate: 4410,  snr: 50, bandwidth: 0.05),
      22050: Resampler(sourceRate: effectiveInputRate, targetRate: 22050, snr: 50, bandwidth: 0.05),
      44100: Resampler(sourceRate: effectiveInputRate, targetRate: 44100, snr: 50, bandwidth: 0.05)
    ]

    // Initialize the filters.
    filters = (0..<128).map { IIRFilter(a: filterA[$0], b: filterB[$0]) }

  }

  /// Processes the supplied buffer to extract its pitch features.
  ///
  /// - Parameters:
  ///   - signal: The signal to process.
  ///   - count: The number of samples in `signal`.
  /// - Returns: The pitch features extracted from `signal`.
  public func process(signal: Float64Buffer, count: Int) -> [PitchVector] {

    // Load compensations.
    for pitch: Pitch in 0 ..< 128 {
      toCompensate[pitch] = resamplers[pitch.sampleRate]!.latency + filterDelays[pitch]
    }

    // Create an array of the sample rates for which there is a resampler.
    let rates: [SampleRate] = [441, 882, 4410, 22050, 44100]


    global.sync {

      // Process `signal` with each resampler to fill the resampled buffers.
      DispatchQueue.concurrentPerform(iterations: rates.count) {
        rateIndex in

        // Get the rate for this iteration.
        let rate = rates[rateIndex]

        let resampledSignal: [Float64]

        if rate == self.sampleRate {

          resampledSignal = Array(UnsafeBufferPointer(start: signal, count: count))

        } else {

          // Get the resampler for `rate`.
          let resampler = self.resamplers[rate]!
          
          // Get the processed signal.
          resampledSignal = resampler.process(source: signal, count: count)

        }


        // Mutate `resampled` on `queue`.
        self.queue.sync {

          // Store the processed signal in the buffer for `rate`.
          self.resampled[rate] = resampledSignal

        }

      }

    }

    // Return the result of filtering the resampled signal buffers.
    return filterResampledBuffers(drain: false)

  }

  /// Processes the supplied buffer to extract its pitch features.
  ///
  /// - Parameter signal: The signal to process.
  /// - Returns: The pitch features extracted from `signal`.
  public func process(signal: AVAudioPCMBuffer) -> [PitchVector] {

    guard let multirateBuffer = try? MultirateAudioPCMBuffer(buffer: signal) else {
      fatalError("Failed to create multirate buffer from provided buffer.")
    }

    return process(signal: multirateBuffer)

  }

  /// Processes the supplied buffer to extract its pitch features.
  ///
  /// - Parameter signal: The signal to process.
  /// - Returns: The pitch features extracted from `signal`.
  public func process(signal: MultirateAudioPCMBuffer) -> [PitchVector] {

    // Insert the buffer signals into the resampled buffers.
    resampled[441]   = Array(signal[441])
    resampled[882]   = Array(signal[882])
    resampled[4410]  = Array(signal[4410])
    resampled[22050] = Array(signal[22050])
    resampled[44100] = Array(signal[44100])

    // Set the flag for specifying the signal has already been resampled.
    multirateSignalBufferProvided = true

    // Load compensations.
//    toCompensate = filterDelays
    for pitch: Pitch in 0 ..< 128 {
      toCompensate[pitch] = 546 + filterDelays[pitch]
    }

    // Return the result of filtering the resampled signal buffers.
    return filterResampledBuffers(drain: false)

  }

  /// Uses zero-padding to flush out values for the portion of the signal held back by latency.
  ///
  /// - Returns: The remaining pitch features.
  public func getRemainingOutput() -> [PitchVector] {

    // Create an array of the sample rates for which there is a resampler.
    let rates: [SampleRate] = [441, 882, 4410, 22050, 44100]

    if multirateSignalBufferProvided {

      guard let audioFormat = AVAudioFormat(commonFormat: .pcmFormatFloat64,
                                            sampleRate: Float64(sampleRate.rawValue),
                                            channels: 1,
                                            interleaved: false)
      else
      {
        fatalError("Failed to create audio format.")
      }

      guard let audioBuffer = AVAudioPCMBuffer(pcmFormat: audioFormat, frameCapacity: 546) else {
        fatalError("Failed to create audio buffer.")
      }

      guard let channelData = audioBuffer.float64ChannelData?.pointee else {
        fatalError("Failed to get channel data.")
      }

      vDSP_vclrD(channelData, 1, 546)
      audioBuffer.frameLength = 546

      guard let multirateBuffer = try? MultirateAudioPCMBuffer(buffer: audioBuffer) else {
        fatalError("Failed to create multirate audio buffer.")
      }

      for rate in rates {
        resampled[rate] = Array(multirateBuffer[rate])
      }

    } else {

      global.sync {

        // Process `signal` with each resampler to fill the resampled buffers.
        DispatchQueue.concurrentPerform(iterations: rates.count) {
          rateIndex in

          // Get the rate for this iteration.
          let rate = rates[rateIndex]

          // Get the latency for `rate`.
          let resampler = self.resamplers[rate]!

          // Create an input signal of all zeros with a length equivalent to the resampler's latency.
          var input = Array<Float64>(repeating: 0, count: resampler.latency)

          // Get the processed signal.
          let resampledSignal = resampler.process(source: &input, count: input.count)

          // Mutate `resampled` on `queue`.
          self.queue.sync {

            // Store the processed signal in the buffer for `rate`.
            self.resampled[rate] = resampledSignal

          }

        }

      }

    }

    // Return the result of filtering zero-padding.
    return filterResampledBuffers(drain: true)

  }

  /// Applies each filter in `filters` to the resampled buffer of its corresponding rate.
  ///
  /// - Parameter drain: Whether to flush features stuck from latency.
  /// - Returns: The pitch features extracted from the current contents of the resampled buffers.
  private func filterResampledBuffers(drain: Bool) -> [PitchVector] {

    // Convert the pitch range into an array for indexing.
    let pitches = Array(pitchRange)

    global.sync {

      DispatchQueue.concurrentPerform(iterations: pitches.count) {
        pitchIndex in

        // Get the pitch for this iteration.
        let pitch = pitches[pitchIndex]

        // Get the signal filtered for `pitch`.
        let filteredSignal = self.filterResampledBuffer(for: pitch, drain: drain)

        // Mutate `filtered` on `queue`.
        self.queue.sync {

          // Store the filtered signal in `filtered`.
          self.filtered[pitch] = filteredSignal

        }

      }

    }

    // Return the energies calculated from `filtered`.
    return energiesFromFiltered(drain: drain)

  }

  /// Applies the filter corresponding to the specified pitch to the resampled buffer for pitch's
  /// sample rate.
  ///
  /// - Parameters:
  ///   - pitch: The pitch for which to filter.
  ///   - drain: Whether features stuck from latency are being flushed.
  /// - Returns: The signal filtered for `pitch`.
  private func filterResampledBuffer(for pitch: Pitch, drain: Bool) -> [Float64] {

    // Get the resampled buffer.
    let resampledSignal = resampled[pitch.sampleRate]!

    // Create a variable initialized with `resampled` as the input signal, zero-padding if `drain`.
    var input = drain
                  ? resampledSignal + Array<Float64>(repeating: 0, count: filterDelays[pitch])
                  : resampledSignal

    // Create an array for the filtered signal.
    var output = Array<Float64>(repeating: 0, count: input.count)

    // Wrap `output` in a `SignalVector` for consumption.
    var outputVector = SignalVector(array: &output)

    // Process the signal using the filter for `pitch`.
    filters[pitch].process(signal: SignalVector(array: &input), y: &outputVector)

    // Create variables for the starting index and count for pushed values.
    var pushStart = 0, pushCount = input.count

    // Check whether there is a delay ƒor which to compensate.
    if toCompensate[pitch] > 0 {

      // Shorten the push count.
      pushCount = max(pushCount - toCompensate[pitch], 0)

      // Adjust `pushStart` for the number of values being dropped.
      pushStart = input.count - pushCount

      // Adjust the compensation value by subtracting the number of values being dropped.
      toCompensate[pitch] -= pushStart

    }

    // Drop the samples before `pushStart`.
    output.removeFirst(pushStart)

    // Return the output.
    return output

  }

  /// Processes the contents of `filtered` to cut frames and calculate energies.
  ///
  /// - Parameter drain: Whether features stuck from latency are being flushed.
  /// - Returns: The pitch features calculated from the current contents of `filtered`.
  private func energiesFromFiltered(drain: Bool) -> [PitchVector] {

    /// A type encapsulating the values needed for calculating pitch energy for a frame.
    struct Frame {

      /// The hop size between frames.
      let hop: Int

      /// The minimum number of samples needed.
      let minimum: Int

      /// The factor by which calculated energy should be multiplied.
      let factor: Float64

      /// The size of the frame in samples.
      let size: Int

      /// Generates a frame for the specified block, rate, tuning ratio and whether to drain.
      ///
      /// - Parameters:
      ///   - block: The block number for the frame.
      ///   - rate: The sample rate for the frame.
      ///   - tuningRatio: The filterbank's tuning ratio.
      ///   - drain: Whether the filterbank is being drained.
      init(for block: Int, rate: SampleRate, tuningRatio: Float64, drain: Bool) {

        factor = 22050 / Float64(rate.rawValue)

        let sizeRatio = tuningRatio / factor

        size = Int((4410 * sizeRatio).rounded())

        let currentStart = Int((2205 * Float64(block) * sizeRatio).rounded())
        let nextStart = Int((2205 * Float64(block + 1) * sizeRatio).rounded())
        hop = nextStart - currentStart

        minimum = drain ? hop : size

      }

    }

    // Create an array of pitches for indexing.
    let pitches = Array(pitchRange)

    // Create a dictionary of current and next window data for each sample rate.
    let frames: [SampleRate:Frame] = [
      441:   Frame(for: blockNo, rate: 441, tuningRatio: tuningRatio, drain: drain),
      882:   Frame(for: blockNo, rate: 882, tuningRatio: tuningRatio, drain: drain),
      4410:  Frame(for: blockNo, rate: 4410, tuningRatio: tuningRatio, drain: drain),
      22050: Frame(for: blockNo, rate: 22050, tuningRatio: tuningRatio, drain: drain),
      44100: Frame(for: blockNo, rate: 44100, tuningRatio: tuningRatio, drain: drain)
    ]

  global.sync {

      DispatchQueue.concurrentPerform(iterations: pitches.count) {
        pitchIndex in

        // Get the pitch for this iteration.
        let pitch = pitches[pitchIndex]

        // Get the windows for `pitch`.
        let frame = frames[pitch.sampleRate]!

        // Get the number of filtered samples for `pitch`.
        let sampleCount = self.filtered[pitch].count

        // Calculate the number of frames to cut.
        let frameCount = Int(Float64(sampleCount) / Float64(frame.hop))

        // Create a buffer for accumulating energy values.
        var energyBuffer: [Float64] = []
        energyBuffer.reserveCapacity(frameCount)

        // Get a pointer to the storage for the pitch's array in `filtered`.
        let filteredSignal = UnsafePointer(self.filtered[pitch])

        // Create a variable for holding a position in the signal.
        var signalOffset = 0

        // Loop while we still have the minimum samples required for a frame.
        while sampleCount - signalOffset >= frame.minimum {

          // Create a variable for holding the sum.
          var energy = 0.0

          // Set the number of values to sum as the frame size or the remaining count.
          let count = min(frame.size, sampleCount - signalOffset)

          // Sum the first `count` values in the offset filtered signal for `pitch`.
          vDSP_svesqD(filteredSignal + signalOffset, 1, &energy, vDSP_Length(count))

          // Store the energy in `energyBuffer`.
          energyBuffer.append(energy * frame.factor)

          // Update the signal offset.
          signalOffset = signalOffset &+ frame.hop

        }

        // Mutate `energies` and `filtered` on `queue`.
        self.queue.sync {

          // Append the calculated energies to `energies`.
          self.energies[pitch].append(contentsOf: energyBuffer)

          // Remove the samples consumed by the energy calculations.
          self.filtered[pitch].removeFirst(frame.hop * frameCount)

        }

      }

    }

    // Increment the block number.
    blockNo = blockNo &+ 1

    // Get length of each pitch's array of energy values.
    let columnCounts = energies[pitchRange].map({Float($0.count)})

    // Get the max or min column count according to whether `drain` is `true`.
    var columnCountf: Float = 0.0
    (drain ? vDSP_maxv : vDSP_minv)(columnCounts, 1, &columnCountf, vDSP_Length(columnCounts.count))

    // Convert the count into an integer.
    let columnCount = Int(columnCountf)

    // Create an array for holding the pitch features.
    var out: [PitchVector] = []
    out.reserveCapacity(columnCount)

    // Fill the array with all-zero pitch vectors.
    for _ in 0 ..< columnCount { out.append(PitchVector()) }

    global.sync {

      DispatchQueue.concurrentPerform(iterations: columnCount) {
        column in

        let vector = out[column]

          for pitch in pitchRange where energies[pitch].count > column {

            (vector.storage + pitch.rawValue).initialize(to: energies[pitch][column])

          }

      }

    }

    // Iterate the energies for pitches in `pitchRange` that aren't empty.
    for pitch in pitchRange where !energies[pitch].isEmpty {

      // Remove at most `columnCount` values from the front of the array.
      energies[pitch].removeFirst(min(columnCount, energies[pitch].count))

    }

    return out

  }

  /// Resets the internal state of the filterbank.
  public func reset() {

    filtered = Array<[Float64]>(repeating: [], count: 128)
    energies = Array<[Float64]>(repeating: [], count: 128)

    blockNo = 0

    multirateSignalBufferProvided = false

    for filter in filters { filter.reset() }

  }

}

private let filterA: [[Float64]] = [
  [],
  [],
  [],
  [],
  [],
  [],
  [],
  [],
  [],
  [],
  [],
  [],
  [],
  [],
  [],
  [],
  [],
  [],
  [],
  [],
  [],
  [1,-7.83971255669754,27.0405109931505,-53.5904705862692,66.7441291922559,-53.4913795620385,26.940605406679,-7.79630509220354,0.99262433569337],
  [1,-7.82062650839427,26.927985683195,-53.3113267851625,66.370845562661,-53.2068960688284,26.8225914438259,-7.77475742515526,0.99218747389046],
  [1,-7.79925010563665,26.8023080768333,-53.000123982319,65.9550962096509,-52.8901357408635,26.6911808450464,-7.75079479903122,0.991724844773134],
  [1,-7.77530937321187,26.6619890340711,-52.6533572558195,65.492304600515,-52.5375983130702,26.5448846532955,-7.72413981620624,0.991234941730303],
  [1,-7.74849811525878,26.5053855413745,-52.2671902915881,64.9774762562405,-52.145455374326,26.3820626098588,-7.69448338390005,0.990716171677742],
  [1,-7.71847428893364,26.3306888814053,-51.837438163363,64.4051811036565,-51.7095337917681,26.2009118944234,-7.661481250987,0.990166850293637],
  [1,-7.68485601408476,26.1359130777835,-51.359553434752,63.7695413069738,-51.2253025470963,25.9994562321024,-7.62475021379531,0.989585197016684],
  [1,-7.64721719457797,25.9188840616538,-50.8286171641556,63.0642268460218,-50.6878645706783,25.7755358240631,-7.58386397239359,0.988969329797661],
  [1,-7.60508272900314,25.6772301554948,-50.2393368014823,62.2824616572183,-50.091955564821,25.5267987064716,-7.53834862188024,0.988317259595919],
  [1,-7.55792329208659,25.4083746556376,-49.5860534453426,61.4170437880926,-49.4319522833409,25.250694327043,-7.48767776782851,0.987626884612688],
  [1,-7.50514967371921,25.1095315258826,-48.8627614827873,60.460383735105,-48.7018932821018,24.9444703567043,-7.43126726177965,0.98689598425276],
  [1,-7.44610667069874,24.7777054988402,-48.0631442569772,59.4045659272379,-47.8955157703003,24.6051740337198,-7.36846956214117,0.986122212807384],
  [1,-7.38006653784084,24.4096982283247,-47.1806300884241,58.2414391610813,-47.0063128613204,24.2296596775261,-7.29856773877113,0.985303092850754],
  [1,-7.30622202099971,24.0021225548032,-46.2084736856305,56.9627426455868,-46.0276162173064,23.8146044182304,-7.22076915687008,0.98443600834411],
  [1,-7.22367901594093,23.5514274457162,-45.1398686730635,55.5602751096721,-44.9527097544936,23.3565346732614,-7.13419889868552,0.983518197441527],
  [1,-7.13144892539892,23.0539367611845,-43.968097560708,54.0261150638639,-43.7749806485168,22.8518664715124,-7.03789301137944,0.982546744993145],
  [1,-7.02844082382798,22.5059056777613,-42.6867258606696,52.3529006465583,-42.4881142307154,22.2969633803355,-6.93079170790297,0.981518574742332],
  [1,-6.91345358751414,21.9035993772566,-41.2898470471472,50.5341773345928,-41.0863393228052,21.688216528775,-6.81173269691909,0.980430441214974],
  [1,-6.78516820950317,21.2433994633917,-39.7723844077554,48.5648209090942,-39.5647298704484,21.0221520282807,-6.67944488014778,0.979278921301082],
  [1,-6.64214059738693,20.5219444801883,-38.1304542047129,46.4415411382231,-37.9195670669097,20.2955719412755,-6.53254273384549,0.978060405530411],
  [1,-6.4827952511242,19.7363118238966,-36.3617914991144,44.1634683235206,-36.1487630564151,19.505735786999,-6.36952178882683,0.976771089046901],
  [1,-6.30542034212456,18.8842491831525,-34.4662349068265,41.7328198023137,-34.2523421979316,18.6505903186322,-6.18875574429359,0.975406962288806],
  [1,-6.10816486880711,17.9644642812777,-32.4462587335652,39.1556364089547,-32.2329680503549,17.7290558252571,-5.98849589904813,0.973963801385493],
  [1,-5.88903875337367,16.9769819368067,-30.3075295473897,36.4425696468955,-30.0964928975817,16.7413773128231,-5.76687376405405,0.972437158284635],
  [1,-5.64591697570834,15.923577023089,-28.0594484033736,33.6096891321511,-27.8524909094812,15.689548321899,-5.5219079376174,0.970822350628849],
  [1,-5.37654911946009,14.8082904011496,-25.715618829875,30.6792675511246,-25.5147151633935,14.577813459499,-5.25151658336892,0.969114451404782],
  [1,-5.07857603859562,13.6380317844759,-23.2941538330808,27.680488658836,-23.1013922942697,13.4132524347226,-4.95353715578909,0.967308278393955],
  [1,-4.7495557451745,12.4232680589918,-20.8177028211003,24.6500157158931,-20.6352368025386,12.2064428081932,-4.62575537077975,0.965398383460352],
  [1,-4.38700107382986,11.1787869173271,-18.3130431024261,21.6323577561748,-18.1430316983389,10.9721899271112,-4.26594581962794,0.963379041717582],
  [1,-3.98843219459661,9.9245126592326,-15.81004438194,18.6799852733962,-15.6545871504486,9.73029957290121,-3.87192706899653,0.961244240625642],
  [1,-3.55144761605267,8.68633236728254,-13.3397859194967,15.8531823087508,-13.2008615998418,8.50635050223996,-3.44163456569275,0.958987669077199],
  [1,-3.07381792789127,7.49686500972951,-10.931597299779,13.2196845770852,-10.8110228713804,7.33239907327814,-2.97321515072195,0.956602706542817],
  [1,-2.55360714353263,6.39607208305034,-8.60882443330873,10.8542444954387,-8.50825926413455,6.24751543465797,-2.46514744505071,0.954082412356116],
  [1,-1.98932706463733,5.4315653954921,-6.38321989057308,8.83837371151665,-6.30424931946652,5.29800976033267,-1.91639274042695,0.951419515232624],
  [1,-1.3801305145541,4.6584158116716,-4.24805643840687,7.26061066603635,-4.19239850517411,4.53715831549695,-1.32658122354503,0.94860640312982],
  [1,-0.726049447802601,4.1382085781884,-2.17040519529578,6.21768004514421,-2.14029045425289,4.02418537477498,-0.696238251729825,0.945635113571624],
  [1,-0.0282836506295197,3.93703202979412,-0.0835420338110394,5.81674345894566,-0.0823144917851033,3.82220420880053,-0.0270548016946264,0.942497324577692],
  [1,0.71045525929924,4.12203818122294,2.1188367580871,6.17843223919996,2.08586704354261,3.99477969641709,0.677795117950928,0.939184346356919],
  [1,1.48554190630691,4.75619479531894,4.58403265666454,7.43933190310684,4.50849787355643,4.60076509963203,1.41328969336724,0.935687113945205],
  [1,-7.43749872761398,24.7295499742871,-47.9474068100488,59.2518997645422,-47.7788570670798,24.5559919298622,-7.3593391322947,0.986012841327085],
  [1,-7.37044001138869,24.3563313062183,-47.0530250575786,58.0734443623397,-46.877802066188,24.1752658641916,-7.28840512567109,0.985187314510369],
  [1,-7.29545983970479,23.9430672019192,-46.0680702017104,56.7782888861502,-45.886334005766,23.7545316499648,-7.2094596266664,0.984313453926318],
  [1,-7.21165163281218,23.4861868645345,-44.9857382567261,55.3582561014742,-44.797741102332,23.2902978630094,-7.12161593331998,0.983388477197058],
  [1,-7.11801325396125,22.9820009745707,-43.7993379299805,53.8054831469656,-43.6054387641476,22.7789694864147,-7.0238973774386,0.982409447590928],
  [1,-7.01343915887258,22.4267608704094,-42.5024913080947,52.1127101907157,-42.3031710113089,22.2169085788341,-6.91523053148921,0.981373266177662],
  [1,-6.89671253661238,21.8167406894037,-41.0893862704878,50.273638034794,-40.8852631948608,21.6005177155461,-6.79443857315565,0.980276663675517],
  [1,-6.7664976710153,21.1483480545567,-39.5550865220872,48.2833618637948,-39.346931713862,20.9263516181663,-6.66023505564044,0.979116191990822],
  [1,-6.62133283295935,20.4182698073457,-37.8959033406807,46.1388862352077,-37.6846545932155,20.1912632403066,-6.51121841257113,0.977888215452043],
  [1,-6.45962411607007,19.6236602006087,-36.1098298301744,43.8397228769258,-35.8966034456585,19.3925914084645,-6.34586762700013,0.976588901743461],
  [1,-6.27964075626953,18.7623797892613,-34.197033057102,41.3885675394881,-33.9831319057289,18.528397840138,-6.16253961834014,0.975214212545844],
  [1,-6.07951263408941,17.8332938546129,-32.1603911895999,38.7920447670014,-31.9473073715259,17.5977618364808,-5.95946905349707,0.973759893895349],
  [1,-5.85723085352634,16.8366393663186,-30.0060508114946,36.0614999109353,-29.7954609985745,16.6011409706265,-5.73477147361815,0.972221466275313],
  [1,-5.61065252858052,15.7744689302863,-27.7439630641513,33.2138063004357,-27.5377145040493,15.5408053736596,-5.48645085060376,0.970594214460172],
  [1,-5.33751119481749,14.6511784793336,-25.388335394267,30.2721431208504,-25.1884207181695,14.4213513540429,-5.21241295247479,0.968873177135641],
  [1,-5.03543460435865,13.4741220765752,-22.9579080426791,27.2666881176414,-22.7664275992666,13.2502965294085,-4.91048620773684,0.96705313632488],
  [1,-4.70197206358,12.2543113825414,-20.4759313858853,24.2351619224784,-20.2950430568863,12.038752692954,-4.57845211831478,0.965128606657046],
  [1,-4.33463393609877,11.0071881487562,-17.9696837019246,21.2231623454708,-17.8015423256508,10.8021633885418,-4.2140876778151,0.963093824521529],
  [1,-3.93094645781054,9.75344440157098,-15.4693331858895,18.2842436563322,-15.3160251537631,9.56107955755732,-3.81522270140406,0.960942737159638],
  [1,-3.48852558740646,8.51984545892155,-13.005921148231,15.4797346999418,-12.8694047685569,8.34192743772245,-3.37981545261811,0.958668991754572],
  [1,-3.00517422587822,7.33998420081358,-10.6082386901586,12.8783563513701,-10.4903077504766,7.1776969046554,-2.90605043699697,0.956265924590691],
  [1,-2.4790077469497,6.25485986333502,-8.2984071562753,10.5557935273876,-8.20070369325379,6.10844461447489,-2.39246268250721,0.953726550364935],
  [1,-1.90861332890381,5.31313036252815,-6.0860818879257,8.59448741919743,-6.01019385276106,5.18146418799022,-1.83809317959833,0.951043551745581],
  [1,-1.29324897591101,4.57083429540065,-3.96141567580436,7.08400465477181,-3.90910433359343,4.45092607013866,-1.24268031558422,0.948209269288255],
  [1,-0.633088227700192,4.09032004026831,-1.88728351197148,6.12234137814057,-1.8608908708547,3.97673561444111,-0.60689197339363,0.945215691834527],
  [1,0.0704838160468424,3.93806119424765,0.208180971112348,5.81831600967038,0.205097934214387,3.82230599890483,0.0673977160859626,0.942054447535886],
  [1,0.814518660513442,4.18099199543821,2.43694409263871,6.29463572002083,2.39872601263877,4.05090483106418,0.776784433799095,0.93871679566537],
  [1,1.59409453498182,4.88098348985287,4.95164252661271,7.69011865217568,4.86940810499708,4.72022941525667,1.51596257982543,0.935193619399812],
  [1,2.40185011521701,6.08713171194664,7.93779845416464,10.1578254395297,7.79819956394451,5.87492510081366,2.27731118298852,0.931475419778803],
  [1,3.22746962821085,7.82568619848761,11.5935542569186,13.8536603875325,11.3776445205571,7.53692455616287,3.05044717106126,0.927552311071793],
  [1,4.05713625657846,10.0877660081552,16.0931105481437,18.9080211030878,15.7757419686594,9.69380413882985,3.82176527065455,0.923414017811578],
  [1,4.87298377929612,12.8155532418934,21.5320008973718,25.3727877923784,21.082357002532,12.2858821855775,4.57399609823065,0.919049873782244],
  [1,5.65259420401527,15.8884757856902,27.8568225872531,33.139752976186,27.2408441749818,15.193568615255,5.28583031900628,0.91444882328108],
  [1,6.36861258072054,19.1120108215486,34.7897446931744,41.8373520517267,33.9751883615237,18.2275236574199,5.93167754133465,0.909599425007868],
  [1,8.75894647337438,35.5865151097657,88.0915877048375,146.922941171414,172.381622832231,144.05510905981,84.6862063356706,33.543111964144,8.09488417362082,0.906155309913276],
  [1,9.37019006762719,40.0149158761222,102.511797656539,174.419106991163,205.914360291568,170.813975352324,98.3179840978953,37.5847598809691,8.6192764829598,0.900861416014772],
  [1,-6.60021538787576,20.3133852992732,-37.6589723173463,45.833328944933,-37.4473828574793,20.0857624339638,-6.48958831669393,0.977714689441037],
  [1,-6.43611088465762,19.5097582119501,-35.855490303689,43.5131243934545,-35.6420903775225,19.2782181680583,-6.32187691376988,0.976405302878619],
  [1,-6.25348404336198,18.6392382147535,-33.9255064001991,41.0415851074297,-33.7116247622536,18.4049587028644,-6.13595386918293,0.97501997157376],
  [1,-6.05044563575328,17.7008550075414,-31.8723131389647,38.4259342252056,-31.6594676135565,17.4652290959481,-5.93003727481345,0.973554411283844],
  [1,-5.82496803512192,16.6950660161854,-29.7025472579297,35.6782261339603,-29.4924389218183,16.4597076133056,-5.7022268414335,0.972004110837553],
  [1,-5.5748906819267,15.6242114579104,-27.4267185846782,32.8161525331391,-27.221216340878,15.3909505935516,-5.45051216231169,0.970364321946706],
  [1,-5.29793139368092,14.4930538565534,-25.0596438522488,29.8638121809353,-24.8607575863557,14.2639171993969,-5.17278699754889,0.968630048797902],
  [1,-4.9917053287308,13.3094047437994,-22.6206903574754,26.852387106751,-22.4305315235645,13.0865755798358,-4.8668713156001,0.966796037454928],
  [1,-4.65375382290777,12.0848350623308,-20.1337007144129,23.820661648517,-19.9544305404798,11.870585616154,-4.53054319452296,0.964856765108824],
  [1,-4.28158578988196,10.8354560530345,-17.6264332005241,20.8153238928718,-17.4602010280144,10.6320436466552,-4.16158309893125,0.962806429220382],
  [1,-3.8727349080991,9.58274299306213,-15.1293170806804,17.8910083919831,-14.9781949909165,9.39226026491719,-3.75783350315999,0.960638936607754],
  [1,-3.42483639984437,8.35435372587666,-12.6732975163208,15.1100813949755,-12.5392226645592,8.17852224342757,-3.31727731265488,0.958347892541437],
  [1,-2.93572782033496,7.18486611434628,-10.2865444856609,12.5422405105896,-10.1712876520382,7.02476262459251,-2.83813901824684,0.955926589919282],
  [1,-2.40357887903817,6.11632217149513,-7.98984601666972,10.2640987004652,-7.89503366660821,5.97202806108635,-2.31901295904884,0.953367998605744],
  [1,-1.82705584953168,5.19842111596153,-5.79062768660099,8.35903302571537,-5.71785456438967,5.06858926003259,-1.75902340279839,0.950664755032824],
  [1,-1.20552649180402,4.48814971126306,-3.67577510073931,6.91766241991176,-3.62685325353022,4.36948992373519,-1.15802127870831,0.947809152174213],
  [1,-0.539311468644628,4.0485791148709,-1.60382460792335,6.03929982977474,-1.58121933174699,3.9352752972064,-0.516822175176644,0.94479313002073],
  [1,0.170012220197387,3.94650013679329,0.50233687939376,5.83448011573347,0.494838990459499,3.82959057344749,0.162510555124906,0.941608266702048],
  [1,0.919251523023273,4.24852629388969,2.7603544944994,6.42803277445532,2.71672364332569,4.11530493381698,0.876335325650053,0.938245770419833],
  [1,1.70317952871362,5.01528775741604,5.32806077440859,7.96098192326598,5.23887850108092,4.8488198012472,1.61905497856969,0.934696472378346],
  [1,2.51406190618728,6.29340154384958,8.39423146563271,10.5877459629868,8.24544364686662,6.07229090526543,2.38269744716203,0.930950820921895],
  [1,3.34113642445435,8.10507899199912,12.1562926052344,14.462889976945,11.9281214766393,7.80367518635356,3.15646582112573,0.926998877114047],
  [1,4.17006400264065,10.4355773663123,16.781312917148,19.7098256929838,16.4477691249988,10.0248574262254,3.92627855132322,0.922830312020985],
  [1,4.98238336169243,13.219280600569,22.3488593446421,26.3639662273258,21.8784874513893,12.6686729582163,4.674333337733,0.918434405991001],
  [1,5.75501989315662,16.326056867468,28.779190797823,34.2874379215653,28.137815126537,15.6064643257793,5.37874515231553,0.913800050254382],
  [],
  [],
  [],
  [],
  [],
  [],
  [],
  []
]

private let filterB: [[Float64]] = [
  [],
  [],
  [],
  [],
  [],
  [],
  [],
  [],
  [],
  [],
  [],
  [],
  [],
  [],
  [],
  [],
  [],
  [],
  [],
  [],
  [0.0031517979535353,-0.0247273529395161,0.0853561885632739,-0.169306632979488,0.211052005541844,-0.169306632979488,0.0853561885632739,-0.0247273529395161,0.0031517979535353],
  [0.00315125171047498,-0.0246636598779945,0.0849922056636697,-0.168414905495119,0.209870226673887,-0.168414905495118,0.0849922056636696,-0.0246636598779945,0.00315125171047497],
  [0.00315068236797476,-0.0245925915500891,0.0845863039165105,-0.167421389633959,0.208554006712421,-0.167421389633959,0.0845863039165104,-0.024592591550089,0.00315068236797475],
  [0.00315008969451907,-0.0245132831910927,0.084133780120015,-0.166315002190551,0.207088857922834,-0.166315002190551,0.084133780120015,-0.0245132831910928,0.00315008969451907],
  [0.00314947358341705,-0.0244247696186714,0.0836294488357889,-0.165083616495825,0.205458969809623,-0.165083616495825,0.083629448835789,-0.0244247696186715,0.00314947358341706],
  [0.00314883407696644,-0.0243259740467123,0.0830676058203103,-0.163714008958029,0.203647153365033,-0.163714008958029,0.0830676058203103,-0.0243259740467123,0.00314883407696644],
  [0.00314817139406315,-0.0242156957893168,0.0824419924425376,-0.162191816262089,0.201634802695257,-0.162191816262089,0.0824419924425377,-0.0242156957893168,0.00314817139406315],
  [0.00314748596170015,-0.0240925967824367,0.0817457625081344,-0.160501508239018,0.199401881209069,-0.160501508239018,0.0817457625081343,-0.0240925967824367,0.00314748596170014],
  [0.00314677845085379,-0.0239551868573306,0.0809714533782964,-0.158626382704875,0.196926941292211,-0.158626382704875,0.0809714533782964,-0.0239551868573306,0.00314677845085379],
  [0.00314604981731641,-0.0238018077112883,0.0801109638552686,-0.15654859008134,0.19418718840176,-0.15654859008134,0.0801109638552687,-0.0238018077112884,0.00314604981731642],
  [0.0031453013481023,-0.0236306155383954,0.0791555420306108,-0.154249197352899,0.191158602792165,-0.154249197352899,0.0791555420306108,-0.0236306155383954,0.00314530134810229],
  [0.00314453471413022,-0.0234395623083114,0.078095787182021,-0.15170830287638,0.187816134595386,-0.15170830287638,0.078095787182021,-0.0234395623083114,0.00314453471413022],
  [0.00314375202997098,-0.0232263757164231,0.0769216708881629,-0.148905215695432,0.184133990648135,-0.148905215695432,0.0769216708881628,-0.023226375716423,0.00314375202997097],
  [0.00314295592154357,-0.0229885378771641,0.0756225838374293,-0.145818715238864,0.180086034158006,-0.145818715238864,0.0756225838374292,-0.022988537877164,0.00314295592154357],
  [0.00314214960275021,-0.0227232628973215,0.0741874163636329,-0.142427409445062,0.175646320816022,-0.142427409445063,0.074187416363633,-0.0227232628973215,0.00314214960275022],
  [0.00314133696215933,-0.0224274735521592,0.0726046825722581,-0.138710211208292,0.170789796979585,-0.138710211208292,0.0726046825722581,-0.0224274735521592,0.00314133696215933],
  [0.00314052266097905,-0.0220977773995409,0.0708627000378196,-0.134646954209011,0.165493186617529,-0.134646954209012,0.0708627000378198,-0.022097777399541,0.00314052266097907],
  [0.003139712243712,-0.0217304428124698,0.0689498394503679,-0.130219169115535,0.159736093219128,-0.130219169115535,0.0689498394503677,-0.0217304428124697,0.00313971224371198],
  [0.00313891226304916,-0.0213213755964652,0.0668548612310698,-0.125411039043509,0.153502340035098,-0.125411039043509,0.0668548612310697,-0.0213213755964651,0.00313891226304915],
  [0.00313813042074587,-0.0208660970944115,0.064567358939396,-0.120210547955736,0.146781565878497,-0.120210547955736,0.0645673589393961,-0.0208660970944115,0.00313813042074588],
  [0.00313737572643158,-0.0203597249791226,0.0620783321029147,-0.114610825947773,0.139571083169271,-0.114610825947773,0.0620783321029148,-0.0203597249791227,0.00313737572643159],
  [0.00313665867653725,-0.0197969583059441,0.0593809136567152,-0.10861167926247,0.131877988830874,-0.10861167926247,0.0593809136567153,-0.0197969583059441,0.00313665867653726],
  [0.00313599145578479,-0.0191720688592899,0.056471279078707,-0.102221268162812,0.123721496093122,-0.102221268162812,0.0564712790787071,-0.01917206885929,0.00313599145578481],
  [0.00313538816397446,-0.0184789013950283,0.0533497649439662,-0.0954578598671861,0.11513542581164,-0.0954578598671862,0.0533497649439663,-0.0184789013950283,0.00313538816397446],
  [0.00313486507113267,-0.0177108860736305,0.0500222231208047,-0.0883515338571114,0.106170760261713,-0.0883515338571112,0.0500222231208045,-0.0177108860736304,0.00313486507113265],
  [0.00313444090444896,-0.0168610672164888,0.0465016319668934,-0.080945650509728,0.0968981230621714,-0.0809456505097281,0.0465016319668935,-0.0168610672164888,0.00313444090444897],
  [0.00313413717084185,-0.0159221535190786,0.0428099759868802,-0.0732978097251405,0.0874100113773252,-0.0732978097251404,0.0428099759868802,-0.0159221535190786,0.00313413717084183],
  [0.00313397851945511,-0.014886596036747,0.038980388281269,-0.0654799248727548,0.0778225802725229,-0.0654799248727548,0.0389803882812689,-0.014886596036747,0.00313397851945511],
  [0.00313399314890581,-0.0137467016335377,0.035059522941777,-0.0575769241541976,0.0682767783956724,-0.0575769241541976,0.035059522941777,-0.0137467016335376,0.00313399314890581],
  [0.00313421326469072,-0.0124947911531448,0.0311100838973822,-0.049683478786989,0.0589386782827374,-0.049683478786989,0.0311100838973822,-0.0124947911531447,0.00313421326469071],
  [0.0031346755928191,-0.0111234133180979,0.0272133786182669,-0.0418980688297514,0.0499989557343147,-0.0418980688297514,0.0272133786182668,-0.0111234133180979,0.00313467559281909],
  [0.00313542195648739,-0.00962562724552086,0.0234716853243965,-0.0343136725822018,0.0416716702058319,-0.0343136725822018,0.0234716853243964,-0.00962562724552084,0.00313542195648737],
  [0.00313649992345948,-0.0079953684004555,0.0200101170746228,-0.0270044650499913,0.034192786399997,-0.0270044650499913,0.0200101170746227,-0.0079953684004555,0.00313649992345948],
  [0.00313796353277989,-0.00622791464464836,0.0169775329904476,-0.0200082208220182,0.0278192248505874,-0.0200082208220182,0.0169775329904476,-0.00622791464464838,0.0031379635327799],
  [0.00313987411054613,-0.00432047054587875,0.0145458869594804,-0.0133047475399193,0.02282953790009,-0.0133047475399193,0.0145458869594803,-0.00432047054587872,0.0031398741105461],
  [0.00314230118572326,-0.0022728889338778,0.0129072248863801,-0.00679175365156629,0.0195273730659838,-0.00679175365156629,0.0129072248863801,-0.0022728889338778,0.00314230118572326],
  [0.00314532351842548,-8.85483003768746e-05,0.0122673609875233,-0.000261191668231923,0.0182483641949064,-0.000261191668231925,0.0122673609875233,-8.85483003768773e-05,0.00314532351842545],
  [0.00314903025475041,0.00222459770166742,0.0128351163207807,0.00661863932542746,0.0193694962772939,0.00661863932542747,0.0128351163207807,0.00222459770166743,0.00314903025475044],
  [0.00315352222417194,0.00465278773047486,0.0148059469814994,0.0143072205586738,0.0233167800327377,0.0143072205586738,0.0148059469814994,0.00465278773047486,0.00315352222417195],
  [0.0031444284886285,-0.023411746004326,0.0779420807991662,-0.151340621773178,0.187332832545537,-0.151340621773178,0.0779420807991663,-0.0234117460043261,0.00314442848862851],
  [0.00314364379976406,-0.0231953400533733,0.0767514995070042,-0.14850000730407,0.183602168182194,-0.14850000730407,0.0767514995070044,-0.0231953400533734,0.00314364379976407],
  [0.00314284608993542,-0.0229539179137308,0.0754344542357878,-0.14537305257123,0.1795021152744,-0.14537305257123,0.0754344542357876,-0.0229539179137307,0.0031428460899354],
  [0.00314203866002239,-0.0226846552140055,0.0739797753871897,-0.141938376211207,0.175006806228633,-0.141938376211206,0.0739797753871896,-0.0226846552140055,0.00314203866002239],
  [0.0031412254982836,-0.0223844330063108,0.0723759381504725,-0.138174977390251,0.170091373758029,-0.138174977390251,0.0723759381504723,-0.0223844330063107,0.00314122549828358],
  [0.00314041137997975,-0.0220498138371481,0.0706112508672007,-0.134062872365675,0.164732865735458,-0.134062872365674,0.0706112508672005,-0.022049813837148,0.00314041137997974],
  [0.00313960197988143,-0.0216770178159089,0.0686741155137211,-0.129583894184265,0.158911378439373,-0.129583894184265,0.0686741155137211,-0.0216770178159089,0.00313960197988143],
  [0.00313880399924279,-0.0212618993765487,0.0665533776980177,-0.124722673903373,0.152611430938886,-0.124722673903373,0.0665533776980176,-0.0212618993765486,0.00313880399924279],
  [0.00313802530901194,-0.0207999256719021,0.0642387863820452,-0.119467815988971,0.145823596688594,-0.119467815988971,0.0642387863820453,-0.0207999256719021,0.00313802530901195],
  [0.00313727511125947,-0.0202861578470912,0.061721586332578,-0.113813270054278,0.138546397167785,-0.113813270054277,0.0617215863325779,-0.0202861578470912,0.00313727511125946],
  [0.00313656412104319,-0.0197152368218753,0.0589952687975133,-0.107759883963412,0.130788445485123,-0.107759883963412,0.0589952687975134,-0.0197152368218753,0.00313656412104319],
  [0.00313590477119144,-0.0190813756868921,0.0560565076720379,-0.101317097236165,0.122570804379238,-0.101317097236165,0.0560565076720379,-0.0190813756868921,0.00313590477119145],
  [0.00313531144278329,-0.0183783614027387,0.0529063088221196,-0.0945046960155996,0.113929492679205,-0.0945046960155996,0.0529063088221196,-0.0183783614027386,0.00313531144278329],
  [0.00313480072443588,-0.0175995692024513,0.0495513983532537,-0.0873544988469494,0.104918037932381,-0.0873544988469494,0.0495513983532537,-0.0175995692024513,0.00313480072443589],
  [0.00313439170388109,-0.0167379939567373,0.046005870168879,-0.0799117737559109,0.0956099334510907,-0.0799117737559109,0.046005870168879,-0.0167379939567373,0.00313439170388109],
  [0.00313410629573131,-0.0157863037864054,0.0422931024188368,-0.072236100373688,0.0861008213998413,-0.0722361003736881,0.042293102418837,-0.0157863037864055,0.00313410629573133],
  [0.00313396960980344,-0.0147369224143719,0.0384479341120715,-0.0644012874509878,0.0765101998091867,-0.0644012874509877,0.0384479341120714,-0.0147369224143719,0.00313396960980342],
  [0.0031340103648984,-0.0135821481510238,0.0345190643652012,-0.0564938420121243,0.0669824555980442,-0.0564938420121243,0.0345190643652012,-0.0135821481510238,0.00313401036489839],
  [0.00313426135352867,-0.0123143190012197,0.0305715939640187,-0.0486093753096016,0.0576870776555341,-0.0486093753096016,0.0305715939640187,-0.0123143190012198,0.00313426135352867],
  [0.00313475996375876,-0.0109260351500444,0.026689568102179,-0.0408462481146363,0.0488180260330958,-0.0408462481146363,0.026689568102179,-0.0109260351500444,0.00313475996375876],
  [0.00313554876508388,-0.00941045197971777,0.0229782961175992,-0.0332957459036623,0.0405924434920703,-0.0332957459036623,0.0229782961175992,-0.00941045197971775,0.00313554876508387],
  [0.00313667616613529,-0.00776165869989687,0.0195661150503689,-0.0260281971817258,0.0332491950042126,-0.0260281971817258,0.0195661150503688,-0.00776165869989685,0.00313667616613528],
  [0.0031381971529815,-0.00597515948154474,0.0166051268891321,-0.0190747949369436,0.0270480708193254,-0.0190747949369435,0.0166051268891321,-0.00597515948154473,0.0031381971529815],
  [0.00314017411791378,-0.0040484754220916,0.0142702761877514,-0.0124055656508274,0.0222707789618359,-0.0124055656508274,0.0142702761877514,-0.00404847542209159,0.00314017411791377],
  [0.00314267778988465,-0.00198188636029559,0.0127559539108768,-0.00590507854279056,0.0192248619731365,-0.00590507854279056,0.0127559539108768,-0.00198188636029558,0.00314267778988464],
  [0.00314578827923778,0.000220669047078714,0.0122691348567959,0.000650792122193332,0.0182510356689205,0.000650792122193331,0.012269134856796,0.000220669047078713,0.0031457882792378],
  [0.00314959625106146,0.0025505192574471,0.0130179171630403,0.00761141762831933,0.019732663335621,0.00761141762831931,0.0130179171630402,0.00255051925744707,0.00314959625106143],
  [0.00315420424345694,0.00499300188718556,0.0151942953598821,0.0154528746866452,0.0241026118421237,0.0154528746866452,0.015194295359882,0.00499300188718553,0.00315420424345691],
  [0.00315972814928869,0.00752602239337344,0.0189501578477618,0.0247531787239567,0.0318372990688839,0.0247531787239566,0.0189501578477617,0.00752602239337343,0.00315972814928869],
  [0.00316629888263797,0.0101184467903849,0.0243659883912773,0.0361284655935598,0.0434208426104726,0.0361284655935597,0.0243659883912771,0.0101184467903849,0.00316629888263794],
  [0.00317406425429049,0.0127283714592526,0.0314127392373057,0.0501183458683116,0.0592559922875406,0.0501183458683117,0.0314127392373057,0.0127283714592526,0.0031740642542905],
  [0.00318319108424792,0.0153013503401604,0.0399090219571167,0.0670148523657365,0.079497650964106,0.0670148523657365,0.0399090219571168,0.0153013503401604,0.00318319108424793],
  [0.0031938675835759,0.017768711714927,0.0494783001754249,0.0866435164030149,0.103796838368635,0.0866435164030151,0.0494783001754251,0.0177687117149271,0.00319386758357593],
  [0.00320630604303235,0.0200461665043228,0.0595142257959717,0.108129205629684,0.130976919400872,0.108129205629684,0.0595142257959717,0.0200461665043228,0.00320630604303236],
  [0.000966737252314877,0.00678719837294068,0.0207529465480032,0.0344257674810349,0.0289103687214516,-1.49402518714571e-16,-0.0289103687214519,-0.034425767481035,-0.0207529465480032,-0.00678719837294067,-0.000966737252314873],
  [0.00102323374378487,0.00768226005382104,0.0246888468368655,0.0423921811893985,0.0363308058052524,3.63343888989567e-15,-0.0363308058052463,-0.042392181189395,-0.0246888468368641,-0.00768226005382073,-0.00102323374378483],
  [0.00313792072867042,-0.0207327847157833,0.063906415267507,-0.118717586752487,0.144856445568187,-0.118717586752487,0.0639064152675069,-0.0207327847157833,0.00313792072867041],
  [0.00313717522787515,-0.0202115208103346,0.0613609186584932,-0.113008230163433,0.137512686946769,-0.113008230163433,0.0613609186584931,-0.0202115208103346,0.00313717522787514],
  [0.00313647052986935,-0.0196323370340034,0.0586056379767411,-0.106900778768694,0.129690268595468,-0.106900778768694,0.0586056379767411,-0.0196323370340034,0.00313647052986934],
  [0.00313581931990023,-0.0189893878102988,0.0556377670229927,-0.10040598441478,0.121412149867308,-0.10040598441478,0.0556377670229926,-0.0189893878102987,0.00313581931990022],
  [0.00313523626517717,-0.0182764025678357,0.0524590069261632,-0.0935451840483572,0.112716595596772,-0.0935451840483573,0.0524590069261632,-0.0182764025678357,0.00313523626517717],
  [0.00313473827836374,-0.0174867021916743,0.049076988873851,-0.0863519622572214,0.103659724902997,-0.0863519622572214,0.0490769888738509,-0.0174867021916742,0.00313473827836373],
  [0.003134344813867,-0.0166132330961708,0.0455069582243649,-0.0788735114588997,0.0943179419992656,-0.0788735114588997,0.0455069582243649,-0.0166132330961707,0.00313434481386699],
  [0.00313407820088497,-0.0156486243579873,0.0417737275984917,-0.0711713902424417,0.0847900663378758,-0.0711713902424418,0.0417737275984919,-0.0156486243579874,0.003134078200885],
  [0.00313396401764996,-0.0145852745818804,0.0379138869743814,-0.0633212750119074,0.075198958502471,-0.0633212750119074,0.0379138869743813,-0.0145852745818804,0.00313396401764995],
  [0.00313403151184234,-0.0134154766000571,0.0339782283123151,-0.0554111853746012,0.065692447729425,-0.0554111853746012,0.0339782283123151,-0.0134154766000571,0.00313403151184234],
  [0.00313431407275455,-0.0121315897258828,0.030034297222116,-0.0475375546983106,0.0564434271791432,-0.0475375546983106,0.030034297222116,-0.0121315897258828,0.00313431407275455],
  [0.00313484976146878,-0.0107262710725034,0.026168920577454,-0.0397984413773646,0.0476491162881336,-0.0397984413773646,0.0261689205774539,-0.0107262710725034,0.00313484976146876],
  [0.00313568190608538,-0.009192779353585,0.0224904725827446,-0.032283178476828,0.0395297124779593,-0.032283178476828,0.0224904725827445,-0.00919277935358497,0.00313568190608537],
  [0.00313685976991731,-0.00752536650751207,0.0191305290351197,-0.0250579069047217,0.0323269642849136,-0.0250579069047216,0.0191305290351197,-0.00752536650751202,0.00313685976991729],
  [0.00313843930156435,-0.00571977426075321,0.016244418759739,-0.0181468230552042,0.0263035484011632,-0.0181468230552042,0.016244418759739,-0.0057197742607532,0.00313843930156434],
  [0.00314048397692068,-0.0037738541070376,0.014010014889563,-0.0115097123022641,0.0217444009057883,-0.0115097123022641,0.014010014889563,-0.0037738541070376,0.00314048397692068],
  [0.00314306574447366,-0.00168832972916368,0.0126239266560126,-0.0050175608333672,0.018961098451767,-0.00501756083336719,0.0126239266560125,-0.00168832972916367,0.00314306574447364],
  [0.00314626608675018,0.000532279948307413,0.0122940765962054,0.00157015821188669,0.0182996231457206,0.00157015821188668,0.0122940765962055,0.000532279948307409,0.00314626608675019],
  [0.00315017721249386,0.00287856193034051,0.0132275188531072,0.00862053107798802,0.0201498602547161,0.00862053107798802,0.0132275188531072,0.00287856193034051,0.00315017721249385],
  [0.00315490339615624,0.00533492576861952,0.0156123376878013,0.0166257862170759,0.024951447525004,0.0166257862170759,0.0156123376878013,0.00533492576861952,0.00315490339615624],
  [0.00316056248360811,0.00787813802996575,0.0195926610689063,0.0261739547654984,0.033184901053375,0.0261739547654985,0.0195926610689064,0.0078781380299658,0.00316056248360813],
  [0.00316728758568919,0.0104756949488836,0.0252363704840063,0.0378787185686475,0.0453299611756,0.0378787185686476,0.0252363704840063,0.0104756949488837,0.0031672875856892],
  [0.00317522898439318,0.0130840806671933,0.0324961592276487,0.0522571528313321,0.0617672642522174,0.052257152831332,0.0324961592276486,0.0130840806671932,0.00317522898439316],
  [0.00318455628022704,0.0156469975174816,0.0411663788666851,0.0695511875977751,0.0825998306110034,0.069551187597775,0.0411663788666851,0.0156469975174816,0.00318455628022703],
  [0.0031954608137085,0.0180937089815597,0.0508407778575426,0.0895040074158415,0.107385387168148,0.0895040074158415,0.0508407778575426,0.0180937089815597,0.0031954608137085],
  [],
  [],
  [],
  [],
  [],
  [],
  [],
  []
]

private let filterDelays: [Int] = [
  0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
  908, 873, 795, 764, 709, 681, 654, 618, 583, 541, 511, 482,
  455, 430, 399, 383, 362, 341, 323, 299, 293, 272, 257, 242,
  237, 212, 211, 193, 185, 172, 157, 156, 137, 142, 127, 122,
  113, 107, 107, 487, 467, 434, 403, 380, 353, 333, 326, 302,
  291, 274, 246, 240, 219, 218, 195, 191, 184, 168, 167, 152,
  144, 138, 133, 121, 124, 108, 99, 97, 88, 92, 82, 77, 74,
  83, 80, 305, 298, 263, 244, 234, 225, 213, 201, 190, 179,
  152, 163, 156, 143, 135, 132, 118, 131, 111, 100, 93, 91, 86, 80, 79,
  0, 0, 0, 0, 0, 0, 0
]
