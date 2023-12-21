extern number timer;

extern number backgroundHeight;
extern number backgroundWidth;

extern number ySpeed;
extern number xSpeed;

extern Image background;

vec4 effect( vec4 color, Image texture, vec2 texture_coords, vec2 screen_coords ){
  vec2 offset = vec2(timer*xSpeed,timer*ySpeed);
  vec4 pixel = Texel(background, (screen_coords/vec2(backgroundWidth,backgroundHeight))+offset);
  return pixel*color;
}