export enum FaultType {
  MemoryPressure = 'memoryPressure',
  MalformedInput = 'malformedInput',
  QuantizationDrift = 'quantizationDrift',
  ThermalThrottle = 'thermalThrottle',
  Latency = 'latency',
  ModelSwap = 'modelSwap',
  ConfidenceValidation = 'confidenceValidation',
  GpuMemoryPressure = 'gpuMemoryPressure',
  DataCorruption = 'dataCorruption',
  ModelVersionMismatch = 'modelVersionMismatch',
  NetworkFailure = 'networkFailure',
}

export const FAULT_TYPE_DISPLAY: Record<FaultType, string> = {
  [FaultType.MemoryPressure]: 'Memory Pressure',
  [FaultType.MalformedInput]: 'Malformed Input',
  [FaultType.QuantizationDrift]: 'Quantization Drift',
  [FaultType.ThermalThrottle]: 'Thermal Throttle',
  [FaultType.Latency]: 'Latency',
  [FaultType.ModelSwap]: 'Model Swap',
  [FaultType.ConfidenceValidation]: 'Confidence Validation',
  [FaultType.GpuMemoryPressure]: 'GPU Memory Pressure',
  [FaultType.DataCorruption]: 'Data Corruption',
  [FaultType.ModelVersionMismatch]: 'Model Version Mismatch',
  [FaultType.NetworkFailure]: 'Network Failure',
};
