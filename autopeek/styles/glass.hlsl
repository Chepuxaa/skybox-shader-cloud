cbuffer cb:register(b0) {float4x4 mvp;float2 tex;float time;float alpha;};
sampler sampler0:register(s0);
Texture2D texture0:register(t0);

struct Input {float4 pos:SV_POSITION;float4 col:COLOR0;float2 uv:TEXCOORD0;};

float2 localUV(float2 encoded, out float visibility) {
    float status=floor(encoded.x*.5);
    float frame=floor(encoded.y*.5);
    float releaseAge=max(status-1,0)/60;
    visibility=lerp(1-smoothstep(0,.28,releaseAge),1,1-step(.5,status));
    return float2(encoded.x-status*2,encoded.y-frame*2)*2-1;
}

float4 main(Input i):SV_Target {
    float visibility;
    float2 p=localUV(i.uv,visibility);
    float radius=length(p);
    float aa=clamp(fwidth(radius),.0015,.025);
    // Discard the square carrier outside the circular effect, including glow tails.
    clip(.90-radius);
    float edge=.83;
    float inside=1-smoothstep(edge-aa,edge+aa,radius);
    float rim=1-smoothstep(.005,.005+aa*.75,abs(radius-edge));
    float rimGlow=exp(-abs(radius-edge)*90)*.08*(1-smoothstep(.865,.90,radius));
    // The GUI projection supplies full viewport dimensions independently of the
    // downsampled background texture. Encoded plane UVs only define the circle.
    float2 viewportScale=float2(abs(mvp[0][0]),abs(mvp[1][1]))*.5;
    float2 screenUV=saturate(i.pos.xy*viewportScale);
    float2 pixel=1.0/max(tex,float2(1,1));
    float3 background=0;
    float total=0;
    [unroll]for(int y=-2;y<=2;y++) {
        [unroll]for(int x=-2;x<=2;x++) {
            float weight=exp(-float(x*x+y*y)/3.5);
            float2 offset=float2(x,y)*pixel*3.0;
            background+=texture0.SampleLevel(sampler0,saturate(screenUV+offset),0).rgb*weight;
            total+=weight;
        }
    }
    background/=total;
    float sheen=exp(-pow((p.y+.20+p.x*.38)*3.1,2))*.06;
    float3 glassColor=lerp(background,i.col.rgb,.12)+sheen;
    float highlight=saturate(.55-p.y*.5-p.x*.22);
    float rimAlpha=saturate(rim*.90+rimGlow);
    float3 rimColor=lerp(i.col.rgb,float3(1,1,1),.30+highlight*.38);
    float3 tint=lerp(glassColor,rimColor,rimAlpha);
    float opacity=saturate(inside*.88+rimAlpha);
    float outputAlpha=opacity*visibility*i.col.a;
    clip(outputAlpha-1.0/1024.0);
    return float4(tint,outputAlpha);
}
