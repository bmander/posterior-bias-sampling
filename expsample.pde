abstract class ProbabilityDensityFunction{
  void draw(int left, int right, float shiftx, float shifty, float sc){
    for(int i=left; i<right; i++){
      line(shiftx+i,height-(shifty+sc*this.probDensity(i)),shiftx+i+1,height-(shifty+sc*this.probDensity(i+1)));
    }
  }
  
  abstract float probDensity(float x);
}

class DoubleExponentialDensityFunction extends ProbabilityDensityFunction{
  float tau;
  DoubleExponentialDensityFunction(float tau){
    this.tau=tau;
  }
  
  float probDensity(float x){
    return 0.5*tau*exp(-tau*abs(x));
  }
}

class UniformDensityFunction extends ProbabilityDensityFunction{
  float low;
  float high;
  
  UniformDensityFunction(float low, float high){
    this.low=low;
    this.high=high;
  }
  
  float probDensity(float x){
    if(x<low || x >high){
      return 0;
    } else {
      return (1/(high-low));
    }
  }
}

class HistogramDensityFunction extends ProbabilityDensityFunction{
  Histogram histogram;
  
  HistogramDensityFunction(Histogram histogram){
    this.histogram=histogram;
  }
  
  float probDensity(float x){
    if(x<histogram.left || x>histogram.right){
      return 0;
    }
    
    //find uniform probibility density of a single bucket
    float bucketdensity = 1/histogram.pitch;
    
    //get probability of picking this bucket
    int bucket=0;
    float bucketprob=0;
    try{
      bucket = histogram.bucket(x);
      bucketprob = histogram.count(bucket)/histogram.mass;
    } catch (ArrayIndexOutOfBoundsException  ex){
      println( this.histogram.left+"-"+this.histogram.right );
      println( x );
      println( bucket );
      println( this.histogram.buckets.length );
      throw ex;
    }
    
    //probability density is the product of the two
    return bucketprob*bucketdensity;
  }
}

class Histogram {
  float left;
  float right;
  float pitch;
  float[] buckets;
  float mass;
  
  Histogram(float left, float right, float pitch){
    this.left = left;
    this.right = right;
    this.pitch = pitch;
    this.buckets = new float[int((right-left)/pitch)+1];
    for(int i=0; i<buckets.length; i++){
      buckets[i]=0;
    }
    mass=0;
  }
  
  void add(float x){
    this.add(x,1);
  }
  
  void add(float x, float weight){

    int bucket = int((x-this.left)/this.pitch);
    this.buckets[bucket] += weight;
    mass += weight;

  }
  
  float count(int bucket){

      return this.buckets[bucket];

  }
  
  int bucket(float val){
    return int((val-this.left)/pitch);
  }
  
  void draw(float shiftx, float shifty){
    strokeWeight(1);
    fill(0);
    noStroke();
    for(int i=0; i<buckets.length; i++){
      float x = left+i*pitch;
      
      float y=buckets[i]/pitch;
      
      
      //line(shift+x,height-0,shift+x,height-y);
      rect(shiftx+x,height-shifty,pitch,-y);
    }
  }
}

ProbabilityDensityFunction true_prior;
ProbabilityDensityFunction bias_prior;

Histogram prior_true_sample_histogram;
Histogram prior_bias_sample_histogram;
Histogram posterior_true_sample_histogram;
Histogram posterior_bias_sample_histogram;

PFont font;

float sc;
float tau;

float uleft=-100;
float uright=100;

float observed_value = 15;

float xshift;
int npanes;
int paneheight;

void setup(){
  size(600,800);
  smooth();
  strokeWeight(1);
  background(255);
  
  sc = height*5;
  tau = 0.1;
  xshift = width/2;
  npanes = 4;
  paneheight = height/npanes;
  
  true_prior = new DoubleExponentialDensityFunction(tau);
  bias_prior = new UniformDensityFunction(uleft,uright);
    
  prior_true_sample_histogram = new Histogram(-width/2,width/2,2);
  prior_bias_sample_histogram = new Histogram(-width/2,width/2,2);
  
  posterior_true_sample_histogram = new Histogram(-width/2,width/2,4);
  posterior_bias_sample_histogram = new Histogram(-width/2,width/2,4);
  
  font = loadFont("ArialMT-14.vlw");
  textFont(font);
  
  strokeWeight(0.01);
  stroke(0,0,0,64);
}

void keyPressed(){
  bias_prior = new HistogramDensityFunction(posterior_bias_sample_histogram);
  
  prior_true_sample_histogram = new Histogram(-width/2,width/2,2);
  prior_bias_sample_histogram = new Histogram(-width/2,width/2,2);
  
  posterior_true_sample_histogram = new Histogram(-width/2,width/2,2);
  posterior_bias_sample_histogram = new Histogram(-width/2,width/2,2);
  
  if(key=='o')
    observed_value=0;
}


//float uniform_sample(float left, float right){
//  return random(left,right);
//}

void draw(){

  for(int i=0; i<20; i++){
    //observed_value = true_value+bias, so bias=observed_value-true_value;
    //sample uniformly: the likelihood weighting takes care of things down the line
    float true_value_sample = random(-100,100);
    float bias_sample = observed_value-true_value_sample;
    prior_true_sample_histogram.add( true_value_sample );
    prior_bias_sample_histogram.add( bias_sample );  
    //likelihood of sample
    float likelihood = true_prior.probDensity(true_value_sample)*bias_prior.probDensity(bias_sample);
    posterior_bias_sample_histogram.add( bias_sample, likelihood*10000 );
    posterior_true_sample_histogram.add( true_value_sample, likelihood*10000 );
  }
  
  background(255);
  
  //draw zero-line
  stroke(0,0,255);
  line(xshift,0,xshift,height);
  

  
  //float bias_sample = uniform_sample(uleft,uright);
  //float true_value_sample = observed_value-bias_sample;
  
  // graph true value prior distribution
  stroke(0);
  prior_true_sample_histogram.draw(xshift, 3*paneheight);
  
  stroke(255,0,0);
  true_prior.draw(-width/2,width/2,xshift,3*paneheight, sc);
  
  // graph bias prior distribution
  stroke(0);
  prior_bias_sample_histogram.draw(xshift, 2*paneheight);
  
  stroke(255,0,0);
  strokeWeight(1);
  bias_prior.draw(-width/2,width/2,xshift,2*paneheight,sc);
  
  // graph observed value
  stroke(0);
  line(xshift+observed_value,height-paneheight,xshift+observed_value,height-2*paneheight);
  

  
  posterior_bias_sample_histogram.draw(xshift,1*paneheight);
  posterior_true_sample_histogram.draw(xshift,0);
  
  text("true value prior distribution\nwith samples before likelihood weighting", 3, 14 );
  text("bias prior distribution\nwith samples before likelihood weighting", 3, 14+paneheight );
  text("bias posterior distribution\nwith observed value", 3, 14+2*paneheight );
  text("true value posterior distribution", 3, 14+3*paneheight );
  fill(0);
  

}
