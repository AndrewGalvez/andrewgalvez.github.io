#version 100
precision mediump float;

varying vec2 fragTexCoord;
varying vec4 fragColor;

#define TEXTURE2D texture2D
#define OUTPUT_COLOR gl_FragColor

uniform sampler2D texture0;
uniform vec4 colDiffuse;
uniform float time;
uniform vec2 resolution;

float random(vec2 st) {
    return fract(sin(dot(st.xy, vec2(12.9898, 78.233))) * 43758.5453123);
}

float blockRandom(vec2 st, float blockSize) {
    vec2 blockPos = floor(st * blockSize);
    return random(blockPos + 0.1 * time);
}

void main() {
    vec4 texelColor = TEXTURE2D(texture0, fragTexCoord);
    
    vec2 screenCoord = gl_FragCoord.xy;
    
    float blockSize = 0.1;
    
    float noise = blockRandom(screenCoord, blockSize);
    
    float grainIntensity = 0.3;
    
    float grain = (noise - 0.5) * grainIntensity;
    
    float luminance = dot(texelColor.rgb, vec3(0.299, 0.587, 0.114));
    
    vec3 grainedColor;
    
    if (luminance < 0.05) {
        grainedColor = texelColor.rgb + abs(grain);
    } else {
        grainedColor = texelColor.rgb + grain;
    }
    
    grainedColor = clamp(grainedColor, 0.0, 1.0);
    
    OUTPUT_COLOR = vec4(grainedColor, texelColor.a) * colDiffuse * fragColor;
}
