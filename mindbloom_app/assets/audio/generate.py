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

# 7. Rain (High-frequency white noise)
rain = [random.uniform(-0.6, 0.6) for _ in range(num_samples)]
save_wav('rain.wav', rain)

# 8. Ocean (Slowly modulated brown noise)
ocean = []
for i in range(num_samples):
    mod = (math.sin(2 * math.pi * i / (sample_rate * 6.0)) + 1.0) / 2.0  # 6-second wave cycle
    ocean.append(stress[i] * mod * 0.8)
save_wav('ocean.wav', ocean)

# 9. Wind (Modulated pink/white noise)
wind = []
for i in range(num_samples):
    mod = 0.5 + 0.5 * math.sin(2 * math.pi * i / (sample_rate * 8.0)) * math.sin(2 * math.pi * i / (sample_rate * 0.5))
    wind.append(random.uniform(-0.5, 0.5) * mod)
save_wav('wind.wav', wind)

# 10. Birds (Periodic high pitch chirps)
birds = [0.0] * num_samples
for chirp_start in range(sample_rate, num_samples - sample_rate * 2, sample_rate * 3):
    # chirp lasts 0.3 seconds
    chirp_len = int(sample_rate * 0.3)
    for j in range(chirp_len):
        idx = chirp_start + j
        # Frequency sweep from 2500Hz to 4000Hz
        freq = 2500 + 1500 * (j / chirp_len)
        birds[idx] = math.sin(2 * math.pi * freq * j / sample_rate) * 0.3
save_wav('birds.wav', birds)

# 11. Forest (Wind + occasional bird chirp)
forest = []
for i in range(num_samples):
    forest.append(wind[i] * 0.7 + birds[i] * 0.6)
save_wav('forest.wav', forest)

# 12. Fire (Crackling noise - random pops overlayed on brown noise)
fire = []
for i in range(num_samples):
    pop = 0.0
    if random.random() < 0.0005:  # Rare crackles
        pop = random.choice([-1.0, 1.0]) * random.uniform(0.5, 1.0)
    fire.append(stress[i] * 0.4 + pop * 0.6)
save_wav('fire.wav', fire)
