ArrayList<Oscil> harmonics = new ArrayList<Oscil>();
Minim minim = new Minim(this);
Summer summer = new Summer();
AudioOutput out = minim.getLineOut();

final int HARMONY_COUNT = 2;
final int NORMAL_FREQ = 440;
final int CLICK_FREQ = 880;

boolean soundWasClicking = false;

void setupSound()
{
  for (int i = 1; i <= HARMONY_COUNT; i++)
  {
    Oscil osc = new Oscil(440*(1+(i*0.5)), 0.01, Waves.SINE);
    harmonics.add(osc);
    osc.patch(summer);
  }
  summer.patch(out);
  
}

void soundHand()
{
   updateOscs(clickTimer/CLICK_TIMER_LIMIT, clicking);
}

void updateOscs(float level, boolean state)
{
  for (int i = 0; i < HARMONY_COUNT; i++)
  {
    Oscil osc = harmonics.get(i);
    float freq = twoDInterpolate(NORMAL_FREQ, CLICK_FREQ, level) * (1+(i*0.5)) * (state ? 2 : 1);
    osc.setFrequency(freq);
    
    float threshDist = 1-(abs(0.5-level) * 2);
    float amp = min(max(pow(threshDist, 0.5), 0), 1);
    println("Level: " + level + "; osc " + i + " at A:" + amp + " F:" + freq);
    osc.setAmplitude(amp);
  }
}