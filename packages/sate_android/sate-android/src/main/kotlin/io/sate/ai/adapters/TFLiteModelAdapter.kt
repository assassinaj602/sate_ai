package io.sate.ai.adapters

import android.content.Context
import io.sate.ai.core.AIInput
import io.sate.ai.core.AIOutput
import org.tensorflow.lite.Interpreter
import java.io.FileInputStream
import java.nio.MappedByteBuffer
import java.nio.channels.FileChannel

class TFLiteModelAdapter(
    context: Context,
    private val modelPath: String,
    override val modelId: String = modelPath.substringAfterLast('/'),
) : ModelAdapter {
    private val interpreter: Interpreter
    private var memoryMB: Double = 0.0
    private var degraded: Boolean = false

    init {
        val model = loadModelFile(context, modelPath)
        interpreter = Interpreter(model)
    }

    override val currentMemoryMB: Double get() = memoryMB
    override val isDegraded: Boolean get() = degraded

    override suspend fun runInference(input: AIInput): AIOutput {
        if (degraded) {
            throw AIInferenceError("TFLite model is degraded")
        }
        val start = System.currentTimeMillis()
        // Placeholder inference. Real usage must resize tensors and feed input.
        val output = Array(1) { FloatArray(1) }
        interpreter.run(floatArrayOf(0f), output)
        val elapsed = System.currentTimeMillis() - start
        return AIOutput(
            text = "TFLite output: ${output[0][0]}",
            inferenceTimeMs = elapsed,
            confidence = 0.9,
        )
    }

    override suspend fun simulateMemoryPressure(mb: Int) {
        memoryMB += mb
        if (memoryMB > 150) degraded = true
    }

    override suspend fun reset() {
        memoryMB = 0.0
        degraded = false
    }

    override suspend fun isHealthy(): Boolean = !degraded && memoryMB < 150

    private fun loadModelFile(context: Context, path: String): MappedByteBuffer {
        val fileDescriptor = context.assets.openFd(path)
        val inputStream = FileInputStream(fileDescriptor.fileDescriptor)
        val fileChannel = inputStream.channel
        return fileChannel.map(
            FileChannel.MapMode.READ_ONLY,
            fileDescriptor.startOffset,
            fileDescriptor.declaredLength,
        )
    }
}
