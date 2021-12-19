const vec3 ColourSkin = vec3(0.25,0.5,0.2)*vec3(0.25,0.5,0.2);
const vec3 ColourLips = vec3(0.56,0.28,0.2)*vec3(0.56,0.28,0.2);
const vec3 ColourWhite = vec3(1.0);
const vec3 ColourBlack = vec3(0.0);
const float MaterialInnerEye = 1.0;
const float MaterialOuterEye = 0.0;
const float MaterialSkin = 2.0;
const float MaterialLips = 3.0;

const vec3 LightColour = vec3(1.0,1.0,0.8);

const float timeStartEyeDetail = 3.2;
const float timeStartMouthDetail = 9.6;

uniform float resolutionX;
uniform float resolutionY;

uniform float pointerX;
uniform float pointerY;

uniform float u_time;

// Generic SDF stuff (obviously not by me)
float Sphere(vec3 point, vec3 center, float radius)
{
    return length(point - center) - radius;
}
float Ellipsoid( in vec3 p, vec3 center, in vec3 r )
{
    return (length( (p-center)/r ) - 1.0) * min(min(r.x,r.y),r.z);
}
float Capsule( vec3 p, vec3 a, vec3 b, float r )
{
    vec3 pa = p - a, ba = b - a;
    float h = clamp( dot(pa,ba)/dot(ba,ba), 0.0, 1.0 );
    return length( pa - ba*h ) - r;
}
// http://research.microsoft.com/en-us/um/people/hoppe/ravg.pdf
float det( vec2 a, vec2 b ) { return a.x*b.y-b.x*a.y; }
vec3 getClosest( vec2 b0, vec2 b1, vec2 b2 )
{
    float a =     det(b0,b2);
    float b = 2.0*det(b1,b0);
    float d = 2.0*det(b2,b1);
    float f = b*d - a*a;
    vec2  d21 = b2-b1;
    vec2  d10 = b1-b0;
    vec2  d20 = b2-b0;
    vec2  gf = 2.0*(b*d21+d*d10+a*d20); gf = vec2(gf.y,-gf.x);
    vec2  pp = -f*gf/dot(gf,gf);
    vec2  d0p = b0-pp;
    float ap = det(d0p,d20);
    float bp = 2.0*det(d10,d0p);
    float t = clamp( (ap+bp)/(2.0*a+b+d), 0.0 ,1.0 );
    return vec3( mix(mix(b0,b1,t), mix(b1,b2,t),t), t );
}
vec4 Bezier( vec3 p, vec3 a, vec3 b, vec3 c )
{
    vec3 w = normalize( cross( c-b, a-b ) );
    vec3 u = normalize( c-b );
    vec3 v = normalize( cross( w, u ) );

    vec2 a2 = vec2( dot(a-b,u), dot(a-b,v) );
    vec2 b2 = vec2( 0.0 );
    vec2 c2 = vec2( dot(c-b,u), dot(c-b,v) );
    vec3 p3 = vec3( dot(p-b,u), dot(p-b,v), dot(p-b,w) );

    vec3 cp = getClosest( a2-p3.xy, b2-p3.xy, c2-p3.xy );

    return vec4( sqrt(dot(cp.xy,cp.xy)+p3.z*p3.z), cp.z, length(cp.xy), p3.z );
}

float UnionRound( float a, float b, float k )
{
    float h = clamp( 0.5 + 0.5*(b-a)/k, 0.0, 1.0 );
    return mix( b, a, h ) - k*h*(1.0-h);
}
vec2 UnionRound( vec2 a, vec2 b, float k )
{
    float h = clamp( 0.5 + 0.5*(b.x-a.x)/k, 0.0, 1.0 );
    return vec2( mix( b.x, a.x, h ) - k*h*(1.0-h), mix( b.y, a.y, h ) );
}
float Union( float a, float b )
{
    return min( a, b );
}
vec2 Union( vec2 a, vec2 b )
{
    return vec2(min( a.x, b.x ), b.y);
}


float SubstractRound( float a, float b, float r )
{
    vec2 u = max( vec2( r + a, r - b ), vec2( 0.0, 0.0 ) );
    return min( -r, max( a, -b ) ) + length( u );
}
vec2 SubstractRound( vec2 a, vec2 b, float r )
{
    return vec2(SubstractRound(a.x,b.x,r), SubstractRound(a.y,b.y,r));
}


// Animation stuff
float DO(float value, float t, float minT)
{
    float dt = clamp(t-minT,0.0,1.0);
    return mix(3.0,value, dt);
}
vec2 DO(vec2 value, float t, float minT)
{
    return vec2(DO(value.x, t, minT),value.y);
}


// Pepe SDF
vec2 doEye(vec3 P, float t)
{
    float outerSocket = Ellipsoid( P, vec3(0.25,0.35,0.6), vec3(0.6,0.4,0.5));
    float innerSocket = Ellipsoid( P, vec3(0.25,0.37,0.75), vec3(0.5,0.22,0.4));
    vec2 innerEye = vec2(Ellipsoid( P, vec3(0.26,0.35,0.8), vec3(0.4,0.2,0.36)), MaterialInnerEye);
    vec2 outerEye = vec2(Ellipsoid( P, vec3(0.25,0.37,0.75), vec3(0.5,0.22,0.4)), MaterialOuterEye);

    outerSocket = DO(outerSocket, t, timeStartEyeDetail);
    innerSocket = DO(innerSocket, t, timeStartEyeDetail+1.6);
    innerEye = DO(innerEye, t, timeStartEyeDetail+2.4);
    outerEye = DO(outerEye, t, timeStartEyeDetail+3.2);

    vec2 eyeSocket = vec2(SubstractRound(
    outerSocket,
    innerSocket,
    0.05 ), MaterialSkin);
    vec2 eye = UnionRound(innerEye, outerEye, 0.001);

    // Eyelid detail
    const float eyelidHeight = 0.58;
    const float eyelidThickness = 0.05;

    vec3 a = vec3(0.0,eyelidHeight-0.05,1.0);
    vec3 b = vec3(0.5,eyelidHeight,1.0);
    vec3 c = vec3(0.7,eyelidHeight-0.15,0.85);
    vec4 eyeLidA = Bezier( P, a, b, c );
    vec2 eyelidDetailA = vec2(eyeLidA.x-eyelidThickness, MaterialSkin);

    a = vec3(0.0,eyelidHeight-0.43,1.0);
    b = vec3(0.5,eyelidHeight-0.47,1.1);
    c = vec3(0.7,eyelidHeight-0.3,0.85);
    vec4 eyeLidB = Bezier( P, a, b, c );
    vec2 eyelidDetailB = vec2(eyeLidB.x-eyelidThickness, MaterialSkin);


    eyelidDetailA = DO(eyelidDetailA, t, timeStartEyeDetail+4.0);
    eyelidDetailB = DO(eyelidDetailB, t, timeStartEyeDetail+4.8);
    vec2 eyelidDetail = UnionRound(eyelidDetailA, eyelidDetailB, 0.01);

    return UnionRound(UnionRound(eye,eyeSocket,0.01), eyelidDetail, 0.05);
}

vec2 doMouth( vec3 P, float t )
{
    float thickness = 0.1;
    float mouthHeight = -0.3;
    float bottomMouthHeight = mouthHeight-0.1;

    vec3 a = vec3(0.0,mouthHeight,1.3);
    vec3 b = vec3(0.3,mouthHeight,1.3);
    vec3 c = vec3(0.6,mouthHeight+0.05,1.1);
    vec4 mouthBezierA = Bezier( P, a, b, c );

    b = c + (c-b); a = c;
    c = vec3(1.0,mouthHeight-0.2,0.50);
    vec4 mouthBezierB = Bezier( P, a, b, c );

    float topMouthA = mouthBezierA.x - thickness;
    float topMouthB = mouthBezierB.x-thickness;
    topMouthA = DO(topMouthA, t, timeStartMouthDetail);
    topMouthB = DO(topMouthB, t, timeStartMouthDetail+0.8);

    float topMouth = Union(topMouthA, topMouthB);

    a = vec3(0.0,bottomMouthHeight,1.3);
    b = vec3(0.3,bottomMouthHeight,1.3);
    c = vec3(0.6,bottomMouthHeight+0.05,1.1);
    vec4 mouthBezierC = Bezier( P, a, b, c );

    b = c + (c-b); a = c;
    c = vec3(1.0,mouthHeight-0.2,0.50);
    vec4 mouthBezierD = Bezier( P, a, b, c );

    float bottomMouthA = mouthBezierC.x - thickness;
    float bottomMouthB = mouthBezierD.x - thickness;
    bottomMouthA = DO(bottomMouthA, t, timeStartMouthDetail+1.6);
    bottomMouthB = DO(bottomMouthB, t, timeStartMouthDetail+2.4);

    float bottomMouth = Union(bottomMouthA,bottomMouthB);

    vec2 fullLips = vec2(Union(topMouth, bottomMouth), MaterialLips);

    return fullLips;
}
vec2 doMouthDetail(vec3 P, float t)
{
    float mouthHeight = -0.4;
    vec3 a = vec3(0.95,mouthHeight+0.1,0.4);
    vec3 b = vec3(1.15,mouthHeight,0.3);
    vec3 c = vec3(0.95,mouthHeight-0.2,0.4);
    vec4 detailBezier = Bezier( P, a, b, c );
    float detail = detailBezier.x - 0.1;
    detail = DO(detail, t, timeStartMouthDetail+3.2);

    return vec2(detail, MaterialSkin);
}

vec2 doPepe(vec3 P, float t)
{
    vec3 symmetricP = vec3(abs(P.x), P.y, P.z);

    vec2 mainHead = vec2(Ellipsoid( P, vec3(0.0,0.0,0.05), vec3(1.0,0.8,1.0)), MaterialSkin);
    //return mainHead;
    vec2 bottomHead = vec2(Ellipsoid( P, vec3(0.0,-0.35,0.15), vec3(0.75,0.5,0.75)*1.5), MaterialSkin);
    vec2 backHead = vec2(Ellipsoid( P, vec3(0.0,-0.4,-0.35), vec3(1.0,0.8,0.75)), MaterialSkin);


    vec2 eyeSocket = vec2(Ellipsoid( symmetricP, vec3(0.25,0.5,0.2), vec3(0.6,0.6,0.6)), MaterialSkin);
    vec2 eye = doEye(symmetricP, t);

    vec2 mouth = doMouth(symmetricP, t);
    vec2 mouthDetail = doMouthDetail(symmetricP, t);

    mainHead = DO(mainHead, t, 0.0);
    bottomHead = DO(bottomHead, t, 0.8);
    backHead = DO(backHead, t, 1.6);
    eyeSocket = DO(eyeSocket, t, 2.4);


    vec2 fullHead = UnionRound(
    UnionRound(mainHead,bottomHead,0.1),
    backHead, 0.2);
    fullHead = UnionRound(fullHead, mouthDetail, 0.1);


    return UnionRound(
    UnionRound(
    UnionRound(fullHead,eyeSocket,0.1),
    mouth, 0.01),
    eye, 0.05);
}

vec2 Scene( vec3 P )
{
    return doPepe(P, u_time);
}

vec3 SceneNormal( in vec3 pos )
{
    vec3 eps = vec3( 0.01, 0.0, 0.0 );
    vec3 normal = vec3(
    Scene( pos + eps.xyy ).x - Scene( pos - eps.xyy ).x,
    Scene( pos + eps.yxy ).x - Scene( pos - eps.yxy ).x,
    Scene( pos + eps.yyx ).x - Scene( pos - eps.yyx ).x );
    return normalize( normal );
}

// Ray marching stuff from iq
float calcSoftShadow( in vec3 ro, in vec3 rd, float k )
{
    float res = 1.0;
    float t = 0.01;
    for( int i=0; i<32; i++ )
    {
        float h = Scene(ro + rd*t ).x;
        res = min( res, smoothstep(0.0,1.0,k*h/t) );
        t += clamp( h, 0.004, 0.1 );
        if( res<0.001 ) break;
    }
    return clamp(res*res,0.0,1.0);
}

vec2 castRay( in vec3 ro, in vec3 rd )
{
    const float maxd = 10.0;

    vec2 h = vec2(1.0,0.0);
    vec2 t = vec2(0.0);

    for ( int i = 0; i < 50; ++i )
    {
        if ( h.x < 0.001 || t.x > maxd )
        {
            break;
        }

        h = Scene( ro + rd * t.x );
        t = vec2(t.x+h.x, h.y);
    }

    if ( t.x > maxd )
    {
        t.x = -1.0;
    }

    return t;
}

// Specular from http://filmicworlds.com/blog/optimizing-ggx-shaders-with-dotlh/
vec2 ggx_fv(float LoH, float a)
{
    float LoH5 = pow(1.0- LoH, 5.0);

    float k = a*0.5;
    float k2 = k*k;
    float ik2 = 1.0-k2;
    float vis = 1.0/(LoH*LoH*ik2+k2);

    return vec2(vis, LoH5*vis);
}
float ggx_d(float NoH, float alpha)
{
    float alphaSqr = alpha*alpha;
    float denom = NoH*NoH*(alphaSqr-1.0)+1.0;
    return alphaSqr/(3.14159*denom*denom);
}
float shade_specular(vec3 N, vec3 V, vec3 L, float roughness, float F0)
{
    vec3 H = normalize(-V+L);
    float LoH = clamp(dot(L,H),0.0,1.0);
    float NoH = clamp(dot(N,H),0.0,1.0);
    float NoL = clamp(dot(L,N),0.0,1.0);

    float alpha = roughness*roughness;
    float D = ggx_d(NoH, alpha);
    vec2 fv = ggx_fv(LoH, alpha);
    float FV = F0*fv.x + (1.0-F0)*fv.y;
    //return D;
    return NoL*D*FV;
}

vec3 shade(vec3 V, vec3 P, vec3 N, float material)
{
    vec3 R = reflect(V, N);

    vec3 diffuseLighting = vec3(0.0);
    vec3 specularLighting = vec3(0.0);

    // Material parameters
    vec3 albedo = mix( ColourWhite, ColourBlack, smoothstep(MaterialOuterEye, MaterialInnerEye, material));
    albedo = mix( albedo, ColourSkin, smoothstep(MaterialInnerEye, MaterialSkin, material));
    albedo = mix( albedo, ColourLips, smoothstep(MaterialSkin, MaterialLips, material));
    float roughness = 0.5*clamp((smoothstep(0.0, MaterialSkin, material))+0.1, 0.0, 1.0);

    // Lighting
    float NoV = clamp(-dot(N, V),0.0,1.0);
    float fresnel = 0.04+0.8*pow(1.0-NoV, 5.0);

    {
        vec3 lightDirection = normalize(vec3(-0.3,1.0,0.1));
        vec3 L = lightDirection;
        float NoL = clamp(dot(L,N),0.0,1.0);
        float shadow = 3.0*NoL*calcSoftShadow(P+N*0.05, lightDirection, 3.0);
        diffuseLighting += LightColour*shadow;
        specularLighting += LightColour*shade_specular(N,V,L, roughness, 0.04);

    }

    diffuseLighting += 0.1*mix( vec3(1.0,0.71,0.51 )*0.5, LightColour*2.0, N.y*0.5+0.5 ); // ambient light

    // Outlines
    float outerEdge = pow(smoothstep(0.0,0.2, NoV), 4.0);
    float materialEdge = abs(fract(material)-0.5)*2.0;
    float edge = (outerEdge*materialEdge)*0.8+0.2;

    return (albedo*diffuseLighting + specularLighting)*edge;
}

vec3 render( vec2 uv, in vec3 ro, in vec3 rd )
{
    vec3 colour = vec3(0.0);

    vec3 V = rd;
    vec2 hit = castRay(ro, rd);
    float depth = hit.x;
    if(hit.x>0.0)
    {
        vec3 pos = ro + hit.x * rd;
        vec3 normal = SceneNormal( pos );
        colour = shade(rd,
        pos, normal, hit.y);
    }
    else
    {
        depth = 100.0;
    }


//    colour = doAtmosphere(colour,
//    uv,
//    ro, rd, depth);
    return colour;
}

mat3 setCamera( in vec3 ro, in vec3 ta, float cr )
{
    vec3 cw = normalize(ta-ro);
    vec3 cp = vec3(sin(cr), cos(cr),0.0);
    vec3 cu = normalize( cross(cw,cp) );
    vec3 cv = normalize( cross(cu,cw) );
    return mat3( cu, cv, cw );
}

void main()
{
    vec2 iResolution = vec2(resolutionX, resolutionY);
    vec2 iMouse = vec2(pointerX, pointerY);

    vec2 uv = gl_FragCoord.xy / iResolution.xy;
    gl_FragColor = vec4(uv,0.5+0.5*sin(u_time),1.0);

    vec2 mo = iMouse.xy/iResolution.xy;
    vec2 p = (-iResolution.xy + 2.0*gl_FragCoord.xy)/iResolution.y;

    // camera
    vec3 ro = vec3( 3.5*cos(6.0*mo.x+u_time*0.1), 2.0*mo.y+0.2, 3.0 + 4.0*sin(6.0*mo.x) );
    vec3 ta = vec3( 0.0, -0.1, 0.5 );
    // camera-to-world transformation
    mat3 ca = setCamera( ro, ta, 0.0 );
    // ray direction
    vec3 rd = ca * normalize( vec3(p.xy,2.0) );

    vec3 colour = render(uv, ro, rd);
    colour = pow(colour, vec3(0.4545));

    gl_FragColor.rgb = colour;

    if (colour.r == 0.0 && colour.g == 0.0 && colour.b == 0.0) gl_FragColor.a = 0.0;
}
