#version 450

layout(push_constant) uniform Push
{
	uint FrameCount;
	float MULTIPLIER;
	float HALATION_INTENSITY;
	float HALATION_RADIUS;
	float HALATION_SAMPLES;
	float HALATION_RANDOM;
	float BLUR_H;
	float BLUR_V;
    float GAMMA_INPUT;
    float GAMMA_OUTPUT;
	float GAMMA_SAMP;
	float MIXING;
	float COLOR_SHIFT;
	float RED_LVL;
	float GREEN_LVL;
	float BLUE_LVL;
    float BRIGHTNESS_LVL;
	float CONTRAST_LVL;
	float SATURATION_LVL;
	float COLOR_BLEED;
	float UNPURE_BLACKS;
	float PHOSPHOR_SIZE;
	float SPLIT;
	float PHOSPHORS;
	float TRIAD_INV;
	float MASK;
	float SCANLINES;
	float SCAN_SHARP;
	float FIELD_SHIFT;
} params;

#pragma parameter MULTIPLIER "Resolution multipler (for high resolution screens)" 1.0 1.0 16.0 0.1
#pragma parameter HALATION_INTENSITY "Halation Intensity" 0.15 0.0 2.0 0.01
#pragma parameter HALATION_RADIUS "Halation Radius" 7.0 0.0 50.0 1.0
#pragma parameter HALATION_SAMPLES "Number of Halation Samples" 28.0 4.0 800.0 4.0
#pragma parameter HALATION_RANDOM "Halation Randomness" 1.0 0.0 1.0 1.0
#pragma parameter BLUR_H "Horizontal Blur" 5.0 0.0 10.0 1.0
#pragma parameter BLUR_V "Vertical Blur" 5.0 0.0 10.0 1.0
#pragma parameter GAMMA_INPUT "Gamma Input" 2.5 0.1 5.0 0.1
#pragma parameter GAMMA_OUTPUT "Gamma Output" 2.2 0.1 5.0 0.1
#pragma parameter GAMMA_SAMP "Sampling Gamma" 2.0 0.1 5.0 0.1
#pragma parameter MIXING "Color Mixing: RGB/HSL/HCL" 2.0 0.0 2.0 1.0
#pragma parameter COLOR_SHIFT "Color Shift" 0.0 0.0 360.0 1.0
#pragma parameter RED_LVL "Red Level" 1.0 0.0 2.0 0.1
#pragma parameter GREEN_LVL "Green Level" 1.0 0.0 2.0 0.1
#pragma parameter BLUE_LVL "Blue Level" 1.0 0.0 2.0 0.1
#pragma parameter BRIGHTNESS_LVL "Brightness" 5.0 0.0 10.0 0.1
#pragma parameter CONTRAST_LVL "Contrast" 5.0 0.0 10.0 0.1
#pragma parameter SATURATION_LVL "Saturation" 5.0 0.0 10.0 0.1
#pragma parameter COLOR_BLEED "Color Bleed" 0.0 0.0 1.0 0.1
#pragma parameter UNPURE_BLACKS "Brightness of pure blacks" 0.0 0.0 1.0 0.01
#pragma parameter SPLIT "Split" 0.0 -1.0 1.0 0.1
#pragma parameter PHOSPHOR_SIZE "Phosphor Size" 3.0 2.0 3.0 1.0
#pragma parameter PHOSPHORS "Phosphors" 0.5 0.0 1.0 0.1
#pragma parameter TRIAD_INV "Invert Phosphor Order" 0.0 0.0 1.0 1.0
#pragma parameter MASK "Slot Mask" 0.5 0.0 1.0 0.1
#pragma parameter SCANLINES "Scanlines" 0.0 0.0 1.0 0.05
#pragma parameter SCAN_SHARP "Scanline Sharpness" 0.5 0.0 1.0 0.05
#pragma parameter FIELD_SHIFT "Alternating Field Shift" 0.0 -2.0 2.0 0.1

layout(std140, set = 0, binding = 0) uniform UBO
{
    mat4 MVP;
    vec4 OutputSize;
    vec4 OriginalSize;
    vec4 SourceSize;
} global;

#pragma stage vertex
layout(location = 0) in vec4 Position;
layout(location = 1) in vec2 TexCoord;
layout(location = 0) out vec2 vTexCoord;

void main()
{
    gl_Position = global.MVP * Position;
    vTexCoord   = TexCoord;
}

/*
 *	Noname CRT Shader by Olivier Doriath
 *	(Loosely based on EasyMode's CRT Shader)
 *	License: GPL
 *
 *	A fancy, fast and heavily configurable CRT shader... At least that's the goal!
 */

#pragma stage fragment
layout(location = 0) in  vec2 vTexCoord;
layout(location = 0) out vec4 FragColor;
layout(set = 0, binding = 2) uniform sampler2D Source;

#define PI 3.1415926535897932384626433832795028841971693994

float rand()
{
	float timer = float(params.FrameCount);
	return fract(sin(vTexCoord.x * vTexCoord.y * timer) * 10000.0);
}

vec3 RGB_HSL(vec3 col)
{
	float R = clamp(col.r, 0.0, 1.0);
	float G = clamp(col.g, 0.0, 1.0);
	float B = clamp(col.b, 0.0, 1.0);

	float C, H, S, V, L;

	V = max(R, max(G, B));
	C = V - min(R, min(G, B));
	L = C * -0.5 + V;

	if(C == 0.0)
	{
		H = 0.0;
	}
	else if(V == R)
	{
		H = mod(60.0 * (G - B) / C, 360.0);
	}
	else if(V == G)
	{
		H = mod(60.0 * ((B - R) / C + 2.0), 360.0);
	}
	else
	{
		H = mod(60.0 * ((R - G) / C + 4.0), 360.0);
	}

	if(C == 0.0)
	{
		S = 0.0;
	}
	else
	{
		S = C / (2.0 * abs(L - 1.0));
	}

	return vec3(H, S, L);
}

vec3 HSL_RGB(vec3 hsl)
{
	float a;
	float H, S, L;
	float R, G, B;

	vec3 k;

	vec3 n = vec3(0.0, 8.0, 4.0);

	H = mod(hsl.x, 360.0);
	S = clamp(hsl.y, 0.0, 1.0);
	L = clamp(hsl.z, 0.0, 1.0);

	a = S * abs(L - 1.0);

	k = mod(n + vec3(H / 30.0), 12.0);

	return L - a * max(vec3(-1.0), min(vec3(1.0), min(k - vec3(3.0), vec3(9.0) - k)));
}

vec3 RGB_HCL(vec3 col)
{
	float R = clamp(col.r, 0.0, 1.0);
	float G = clamp(col.g, 0.0, 1.0);
	float B = clamp(col.b, 0.0, 1.0);

	float C, H, V, L;

	V = max(R, max(G, B));
	C = V - min(R, min(G, B));
	L = V - C / 2.0;

	if(C == 0.0)
	{
		H = 0.0;
	}
	else if(V == R)
	{
		H = mod(60.0 * (G - B) / C, 360.0);
	}
	else if(V == G)
	{
		H = mod(60.0 * (2.0 + (B - R) / C), 360.0);
	}
	else
	{
		H = mod(60.0 * (4.0 + (R - G) / C), 360.0);
	}

	return vec3(H, C, L);
}

vec3 HCL_RGB(vec3 hsl)
{
	float a;
	float H, S, L;
	float R, G, B;

	vec3 k;

	vec3 n = vec3(0.0, 8.0, 4.0);

	H = mod(hsl.x, 360.0);
	S = clamp(hsl.y, 0.0, 1.0);
	L = clamp(hsl.z, 0.0, 1.0);

	if(hsl.y == 0.0)
		S = 0.0;
	else
		S = clamp(hsl.y / (2.0 * min(L, 1.0 - L)), 0.0, 1.0);

	a = clamp(hsl.y / 2.0, 0.0, 1.0);

	k = mod(n + vec3(H / 30.0), 12.0);

	return L - a * max(vec3(-1.0), min(vec3(1.0), min(k - vec3(3.0), vec3(9.0) - k)));
}

vec3 ColMix(vec3 l_col, vec3 r_col, float fac)
{
	float H, S, C, L;
	float x, y;
	vec3 col;
	if(params.MIXING == 0.0)
	{
		return mix(l_col, r_col, fac);
	}
	else if(params.MIXING == 1.0)
	{
		l_col = RGB_HSL(l_col);
		r_col = RGB_HSL(r_col);

		x = cos(l_col.x / 180.0 * PI) * l_col.y * (1.0 - fac);
		x += cos(r_col.x / 180.0 * PI) * r_col.y * fac;

		y = sin(l_col.x / 180.0 * PI) * l_col.y * (1.0 - fac);
		y += sin(r_col.x / 180.0 * PI) * r_col.y * fac;

		H = atan(y, x) * 180.0 / PI;
		S = length(vec2(x, y));
		L = mix(l_col.z, r_col.z, fac);

		return HSL_RGB(vec3(H, S, L));
	}
	else 
	{
		l_col = RGB_HCL(l_col);
		r_col = RGB_HCL(r_col);

		x = cos(l_col.x / 180.0 * PI) * l_col.y * (1.0 - fac);
		x += cos(r_col.x / 180.0 * PI) * r_col.y * fac;

		y = sin(l_col.x / 180.0 * PI) * l_col.y * (1.0 - fac);
		y += sin(r_col.x / 180.0 * PI) * r_col.y * fac;

		H = atan(y, x) * 180.0 / PI;
		C = length(vec2(x, y));
		L = mix(l_col.z, r_col.z, fac);

		return HCL_RGB(vec3(H, C, L));
	}
}
vec3 ColGen(sampler2D source, vec2 coords)
{
	vec2 dx    		= vec2(global.SourceSize.z, 0.0);
    vec2 dy			= vec2(0.0, global.SourceSize.w);

    vec2 pix_co		= (coords) * global.SourceSize.xy;
    vec2 tex_co 	= (floor(pix_co) + vec2(0.5, 0.5)) * global.SourceSize.zw;

	vec2 x_shift	= params.FIELD_SHIFT * vec2((floor(mod(pix_co.y + 0.0, 2.0)) - 0.5) * dx.x, 0.0);
	vec2 y_shift	= params.FIELD_SHIFT * vec2((floor(mod(pix_co.y + 1.0, 2.0)) - 0.5) * dx.x, 0.0);

    vec2 pix_co_x	= (coords + x_shift) * global.SourceSize.xy;

    vec2 pix_co_y	= (coords + y_shift) * global.SourceSize.xy;

    vec2 dist		= fract(pix_co);
    vec2 dist_x		= fract(pix_co_x);
    vec2 dist_y		= fract(pix_co_y);

	float x_smooth	= params.BLUR_H / 20.0;
	float y_smooth	= params.BLUR_V / 20.0;

	vec3 col, col2, col3, col4;

	/*
	 * A B C
	 * D E F
	 * G H I
	 */

	vec3 A, B, C, D, E, F, G, H, I;

	vec3 gamma = vec3(params.GAMMA_SAMP);

	A = pow(texelFetch(source, ivec2(pix_co_y) + ivec2(-1, -1), 0).rgb, gamma);
	B = pow(texelFetch(source, ivec2(pix_co_y) + ivec2( 0, -1), 0).rgb, gamma);
	C = pow(texelFetch(source, ivec2(pix_co_y) + ivec2( 1, -1), 0).rgb, gamma);
	D = pow(texelFetch(source, ivec2(pix_co_x) + ivec2(-1,  0), 0).rgb, gamma);
	E = pow(texelFetch(source, ivec2(pix_co_x) + ivec2( 0,  0), 0).rgb, gamma);
	F = pow(texelFetch(source, ivec2(pix_co_x) + ivec2( 1,  0), 0).rgb, gamma);
	G = pow(texelFetch(source, ivec2(pix_co_y) + ivec2(-1,  1), 0).rgb, gamma);
	H = pow(texelFetch(source, ivec2(pix_co_y) + ivec2( 0,  1), 0).rgb, gamma);
	I = pow(texelFetch(source, ivec2(pix_co_y) + ivec2( 1,  1), 0).rgb, gamma);

	B = ColMix(ColMix(B, A, x_smooth), ColMix(B, C, x_smooth), dist_y.x);

	E = ColMix(ColMix(E, D, x_smooth), ColMix(E, F, x_smooth), dist_x.x);

	H = ColMix(ColMix(H, G, x_smooth), ColMix(H, I, x_smooth), dist_y.x);

	E = ColMix(ColMix(E, B, y_smooth), ColMix(E, H, y_smooth), dist.y);


	E = RGB_HCL(E);

	E.x = mod(E.x + params.COLOR_SHIFT, 360.0);

	E = HCL_RGB(E);

	return pow(E, 1.0 / gamma);
}

vec3 Halation(vec2 coords)
{
	vec2 dx			= vec2(global.SourceSize.z, 0.0);
    vec2 dy			= vec2(0.0, global.SourceSize.w);

	float radius	= params.HALATION_RADIUS;
	float samples	= params.HALATION_SAMPLES / 4.0;

	float div_total	= 0.0;
	vec3 col		= vec3(0.0, 0.0, 0.0);

	float ratio		= 1.0;

	if(params.HALATION_RANDOM == 1.0)
		ratio = rand() * 2.0;

	float div = 1.0;

	for(float i = 1.0; i <= samples; i++)
	{
		div = 1.0 / sqrt(i);
		div_total		+= 4.0 * div;

		col		+= texture(Source, coords + vec2(
					radius * i / samples * cos(i * ratio) * dx.x,
					radius * i / samples * sin(i * ratio) * dy.y
				)).rgb * div;

		col		+= texture(Source, coords - vec2(
					radius * i / samples * cos(i * ratio) * dx.x,
					radius * i / samples * sin(i * ratio) * dy.y
				)).rgb * div;

		col		+= texture(Source, coords + vec2(
					radius * i / samples * cos(i * ratio + PI/2) * dx.x,
					radius * i / samples * sin(i * ratio + PI/2) * dy.y
				)).rgb * div;

		col		+= texture(Source, coords - vec2(
					radius * i / samples * cos(i * ratio + PI/2) * dx.x,
					radius * i / samples * sin(i * ratio + PI/2) * dy.y
				)).rgb * div;

	}
	col = max(col, 0.0);
	col /= div_total;

	col = RGB_HCL(col);
	col.x = mod(col.x + params.COLOR_SHIFT, 360.0);
	col = HCL_RGB(col);

	return col;
}


/* main_fragment */
void main()
{
    vec3 col;
	vec3 levels = vec3(params.RED_LVL, params.GREEN_LVL, params.BLUE_LVL);

	vec3 hal = vec3(0.0);

	if(vTexCoord.x - params.SPLIT - 1.0 > 0.0 || vTexCoord.x - params.SPLIT < 0.0)
	{
		FragColor = vec4(texture(Source, vTexCoord).rgb, 1.0);
	}
	else
	{
		if (params.HALATION_INTENSITY > 0.0)
		{
			hal = Halation(vTexCoord);
		}

		col = ColGen(Source, vTexCoord);

		col = pow(col, vec3(params.GAMMA_INPUT));

		float p = 1.0 - params.PHOSPHORS;

		vec2 mod_fac = floor(vTexCoord * global.OutputSize.xy);
		int dot_no   = int(mod(floor(mod_fac.x / params.MULTIPLIER), params.PHOSPHOR_SIZE));
		vec3 mask_weight;

		if (params.PHOSPHOR_SIZE == 3.0)
		{
			if (params.TRIAD_INV == 0.0)
			{
				if (dot_no == 0) 
				{
					mask_weight = vec3(1.0, p, p);
				}
				else if (dot_no == 1)
				{
					mask_weight = vec3(p, 1.0, p);
				}
				else
				{
					mask_weight = vec3(p, p, 1.0);
				}
			}
			else
			{
				if (dot_no == 0) 
				{
					mask_weight = vec3(p, p, 1.0);
				}
				else if (dot_no == 1)
				{
					mask_weight = vec3(p, 1.0, p);
				}
				else
				{
					mask_weight = vec3(1.0, p, p);
				}
			}
		}
		else
		{
			if (params.TRIAD_INV == 0.0)
			{
				if (dot_no == 0) 
				{
					mask_weight = vec3(1.0, p, 1.0);
				}
				else
				{
					mask_weight = vec3(p, 1.0, p);
				}
			}
			else
			{
				if (dot_no == 0) 
				{
					mask_weight = vec3(p, 1.0, p);
				}
				else
				{
					mask_weight = vec3(1.0, p, 1.0);
				}
			}
		}

		col *= mask_weight;

		float height_ratio = global.OutputSize.y / global.OriginalSize.y;

		if (height_ratio < 2.0)
			height_ratio = 2.0;

		col -= col * smoothstep(params.SCAN_SHARP/2.0 - 0.01,(1.0 - params.SCAN_SHARP/2.0),mod(vTexCoord.y * global.OutputSize.y, round(height_ratio))/round(height_ratio)) * params.SCANLINES;

		if (((mod(ceil(vTexCoord.y * global.OutputSize.y / params.MULTIPLIER), params.PHOSPHOR_SIZE + 1.0) == 0.0)
		|| (mod(ceil(vTexCoord.x * global.OutputSize.x / params.PHOSPHOR_SIZE / params.MULTIPLIER), 2.0) == 0.0))
		&& ((mod(ceil(vTexCoord.y * global.OutputSize.y / params.MULTIPLIER), params.PHOSPHOR_SIZE + 1.0) == 2.0)
		|| (mod(ceil(vTexCoord.x * global.OutputSize.x / params.PHOSPHOR_SIZE / params.MULTIPLIER), 2.0) == 1.0)))
		{
			col = col * vec3(1.0 - params.MASK);
		}

		col += params.HALATION_INTENSITY * pow(hal, vec3(params.GAMMA_INPUT));

		col = max(vec3(params.UNPURE_BLACKS / 5.0), col);

		col *= params.CONTRAST_LVL / 5.0;
		col += params.BRIGHTNESS_LVL - 5.0;

		vec3 saturation = vec3(0.3 * col.r, 0.59 * col.g,0.11 * col.b) * (5.0 - params.SATURATION_LVL) / 5.0;
		col = (col * params.SATURATION_LVL / 5.0) + vec3(saturation.r + saturation.g + saturation.b);

		vec3 bleed = vec3(0.0);

		col *= levels;

		if(params.COLOR_BLEED != 0.0)
		{
			if(col.r > 0.5)
			{
				bleed.g = (col.r - 0.5);
			}
			if(col.g > 0.5)
			{
				bleed.r = (col.g);
				bleed.b = (col.g);
			}
			if(col.b > 0.5)
			{
				bleed.g = (col.b - 0.5);
			}
			if(params.COLOR_BLEED <= 1.0)
				col = max(col, params.COLOR_BLEED * bleed);
			else
				col = bleed;
		}

		col = pow(col, vec3(1.0 / params.GAMMA_OUTPUT));

		FragColor = vec4(col, 1.0);
	}
}
