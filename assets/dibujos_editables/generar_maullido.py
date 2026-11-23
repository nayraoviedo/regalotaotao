"""Maullido de prueba del pomodoro, hecho con matemática (no es grabado).

Para cambiarlo por uno de verdad basta con reemplazar
assets/sonidos/raw/maullido.mp3 (mismo nombre, en minúsculas).

Para volver a generar este:
  python3 generar_maullido.py
  ffmpeg -i maullido.wav -codec:a libmp3lame -b:a 96k ../sonidos/raw/maullido.mp3
"""
import numpy as np, wave
sr=44100; dur=0.95
t=np.arange(int(sr*dur))/sr; x=t/dur
# tono: sube y luego baja (mi-AU)
f0=520+330*np.sin(np.pi*np.clip(x*1.25,0,1))**1.3 - 120*np.clip((x-0.6)/0.4,0,1)
f0*=1+0.012*np.sin(2*np.pi*6*t)
phase=2*np.pi*np.cumsum(f0)/sr
# formantes: "i" -> "a" -> "u"
def lerp3(a,b,c):
    return np.where(x<0.45, a+(b-a)*x/0.45, b+(c-b)*(x-0.45)/0.55)
F1=lerp3(500,1000,650); F2=lerp3(2300,1500,1000); F3=lerp3(3200,2700,2500)
def res(f,F,bw): return 1/(1+((f-F)/bw)**2)
y=np.zeros_like(t)
for k in range(1,14):
    fk=k*f0
    a=(res(fk,F1,180)+0.7*res(fk,F2,220)+0.35*res(fk,F3,300))/k**0.6
    a[fk>sr/2-500]=0
    y+=a*np.sin(k*phase)
noise=np.random.default_rng(1).standard_normal(len(t))
y+=0.02*np.convolve(noise,np.ones(8)/8,'same')
env=np.clip(x/0.08,0,1)**1.5*np.clip((1-x)/0.3,0,1)**1.2
env*=1+0.15*np.sin(np.pi*x)
y*=env
y=y/np.max(np.abs(y))*0.85
pad=np.zeros(int(sr*0.05))
y=np.concatenate([pad,y,pad])
with wave.open('maullido.wav','wb') as w:
    w.setnchannels(1); w.setsampwidth(2); w.setframerate(sr)
    w.writeframes((y*32767).astype('<i2').tobytes())
