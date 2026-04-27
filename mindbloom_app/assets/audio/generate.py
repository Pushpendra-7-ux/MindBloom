import wave
import struct
import math
import random
import os

sample_rate = 44100
duration = 10 # 10 seconds

def save_wav(filename, samples):
    with wave.open(filename, 'w') as wav_file:
        wav_file.setnchannels(1)
        wav_file.setsampwidth(2)
        wav_file.setframerate(sample_rate)
        
        # Scale to max volume
        max_val = max(abs(max(samples)), abs(min(samples)), 1e-6)
        scaled_samples = [int(s / max_val * 32767) for s in samples]
        
        for sample in scaled_samples:
            wav_file.writeframes(struct.pack('<h', sample))
    print(f"Generated {filename}")

num_samples = sample_rate * duration

# 1. Calm (432Hz Sine Wave)
calm = [math.sin(2 * math.pi * 432 * i / sample_rate) for i in range(num_samples)]
save_wav('calm.wav', calm)

# 2. Focus (White noise approximation of Pink)
focus = [random.uniform(-1, 1) for _ in range(num_samples)]
save_wav('focus.wav', focus)

# 3. Stress (Brown Noise approximation - cumulative sum of white noise)
stress = []
val = 0
for _ in range(num_samples):
    val += random.uniform(-0.1, 0.1)
    val = max(-1, min(1, val)) # Clamping
    stress.append(val)
save_wav('stress.wav', stress)

# 4. Sleep (Modulated Brown Noise like waves)
sleep = []
for i in range(num_samples):
    mod = (math.sin(2 * math.pi * i / (sample_rate * 5)) + 1) / 2  # 5s waves
    sleep.append(stress[i] * mod)
save_wav('sleep.wav', sleep)

# 5. Body (528Hz Sine + slight noise)
body = [(math.sin(2 * math.pi * 528 * i / sample_rate) * 0.8 + random.uniform(-0.2, 0.2)) for i in range(num_samples)]
save_wav('body.wav', body)

# 6. Gratitude (396Hz Sine)
gratitude = [math.sin(2 * math.pi * 396 * i / sample_rate) for i in range(num_samples)]
save_wav('gratitude.wav', gratitude)
