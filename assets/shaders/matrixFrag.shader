varying vec2 vTextureCoord;
uniform vec4 uBackgroundColor;
uniform vec4 uRainColor;
uniform float uCount;
uniform vec2 uTextureSize;
uniform float uTime;
uniform float uTrail;
uniform float uSpeed;

uniform sampler2D uSampler;

float random(vec2 st) {
    return fract(sin(dot(st.xy,vec2(12.9898,78.233))) * 43758.5453123);
}

float text(vec2 uv) {
    float tileSize = 16.;
    vec2 dim = tileSize / uTextureSize;

    vec2 fragCoord = uv * uTextureSize;
    vec2 localUV = mod(fragCoord.xy, tileSize) * dim;
    vec2 block = fragCoord * dim - localUV;

    localUV += floor((random(block / uTextureSize) + uTime * 0.1) * tileSize);
    localUV *= dim;

    return texture2D(uSampler, localUV).r;
}


float rain(vec2 uv) {
    vec2 fragCoord = uv * uTextureSize;

    fragCoord -= mod(fragCoord, 16.);

    float offset = sin(fragCoord.x * 10.);
    float y = fract(-uv.y + offset + uSpeed * uTime);

    float trailFactor = 1. / (y * uTrail);

    return clamp(0., 1., trailFactor);
}


void main(void)
{
    vec2 uv = vTextureCoord;

    float rainFactor = rain(uv);
    float textFactor = text(uv);

    gl_FragColor = mix(uBackgroundColor, uRainColor, rainFactor * textFactor);
}
