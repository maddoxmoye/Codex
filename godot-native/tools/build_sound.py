"""Original synthesized sounds for the Emberwood study; no third-party recordings."""
from pathlib import Path
import math, random, struct, wave
root=Path(__file__).resolve().parents[1]/'assets'/'audio'
root.mkdir(parents=True,exist_ok=True)
rate=22050
random.seed(1947)
def write(name,seconds,fn):
 out=bytearray();state=0.
 for i in range(int(seconds*rate)):
  t=i/rate;u=t/seconds
  state=state*.92+random.uniform(-1,1)*.08
  sample=fn(t,u,state)
  out.extend(struct.pack('<h',int(max(-.98,min(.98,sample))*32767)))
 with wave.open(str(root/(name+'.wav')),'wb') as w:
  w.setnchannels(1);w.setsampwidth(2);w.setframerate(rate);w.writeframes(out)
write('bow',.19,lambda t,u,n:(math.sin(2*math.pi*(430*t-850*t*t))*.2+n*2.4)*math.exp(-u*8)*min(1,u*100))
write('arrow_hit',.17,lambda t,u,n:(n*2.2+math.sin(2*math.pi*165*t)*.24)*math.exp(-u*8))
write('windskip',.4,lambda t,u,n:n*1.6*math.sin(math.pi*u)**1.2)
write('salvo',.6,lambda t,u,n:(math.sin(2*math.pi*(330*t+340*t*t))*.16+math.sin(2*math.pi*660*t)*.08+n*.4)*math.sin(math.pi*u)**2)
write('hurt',.24,lambda t,u,n:(n*1.5+math.sin(2*math.pi*93*t)*.3)*math.exp(-u*7))
write('slam',.9,lambda t,u,n:(math.sin(2*math.pi*(57*t-18*t*t))*.65+n*2)*math.exp(-u*6)*min(1,u*80))
write('chime',.7,lambda t,u,n:(math.sin(2*math.pi*880*t)*.18+math.sin(2*math.pi*1320*t)*.1)*math.exp(-u*6)*min(1,u*60))
# Seamless low woodland air bed; smooth envelope avoids an audible loop seam.
write('woodland_air',12,lambda t,u,n:n*.6*math.sin(math.pi*u)**.25 + math.sin(2*math.pi*44*t)*.008*math.sin(math.pi*u)**2)
print('Generated original audio:',len(list(root.glob('*.wav'))),'sounds')
