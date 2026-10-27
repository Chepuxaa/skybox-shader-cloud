cbuffer Custom : register(b6) {
    float4 c_params;
    float4 c_low;
    float4 c_high;
    float4 c_glow;
};
struct ps_in { float3 dir : TEXCOORD0; float4 position : SV_Position; };
float4 main(ps_in i) : SV_Target0 {
    float3 d = normalize(i.dir);
    float az = atan2(d.y,d.x);
    float elevation = asin(clamp(d.z,-1.0,1.0));
    float phase = c_params.y < 0.5 ? 0.0 : c_params.x*0.65;
    float bend = 0.0;
    if (c_params.y > 1.5)
        bend = sin(az*3.0+c_params.x)*c_params.z*0.22;
    float bands = (elevation+bend)*c_low.a-phase;
    float distance = abs(frac(bands+0.5)-0.5);
    float aa = max(fwidth(bands),0.001);
    float stripe = 1.0-smoothstep(c_high.a-aa,c_high.a+aa,distance);
    float halo = exp(-distance*distance/0.015)*c_params.w;
    float horizon = saturate(length(d.xy)*4.0);
    float h = saturate(d.z*0.5+0.5);
    float3 color = lerp(c_low.rgb,c_high.rgb,h);
    color += c_glow.rgb*(stripe+halo)*horizon;
    return float4(color,1.0);
}
