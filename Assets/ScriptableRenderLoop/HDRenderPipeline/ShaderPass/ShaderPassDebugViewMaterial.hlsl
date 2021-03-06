#if SHADERPASS != SHADERPASS_DEBUG_VIEW_MATERIAL
#error SHADERPASS_is_not_correctly_define
#endif

#include "Color.hlsl"
int _DebugViewMaterial;

#include "VertMesh.hlsl"

PackedVaryingsType Vert(AttributesMesh inputMesh)
{
    VaryingsType varyingsType;
    varyingsType.vmesh = VertMesh(inputMesh);
    return PackVaryingsType(varyingsType);
}

#ifdef TESSELLATION_ON

PackedVaryingsToPS VertTesselation(VaryingsToDS input)
{
    VaryingsToPS output;
    output.vmesh = VertMeshTesselation(input.vmesh);
    return PackVaryingsToPS(output);
}

#include "TessellationShare.hlsl"

#endif // TESSELLATION_ON
			
float4 Frag(PackedVaryingsToPS packedInput) : SV_Target
{
    FragInputs input = UnpackVaryingsMeshToFragInputs(packedInput.vmesh);

    // input.unPositionSS is SV_Position
    PositionInputs posInput = GetPositionInput(input.unPositionSS.xy, _ScreenSize.zw);
    UpdatePositionInput(input.unPositionSS.z, input.unPositionSS.w, input.positionWS, posInput);
    float3 V = GetWorldSpaceNormalizeViewDir(input.positionWS);

	SurfaceData surfaceData;
	BuiltinData builtinData;
	GetSurfaceAndBuiltinData(input, V, posInput, surfaceData, builtinData);

	BSDFData bsdfData = ConvertSurfaceDataToBSDFData(surfaceData);

	float3 result = float3(1.0, 0.0, 1.0);
	bool needLinearToSRGB = false;

	GetVaryingsDataDebug(_DebugViewMaterial, input, result, needLinearToSRGB);
	GetBuiltinDataDebug(_DebugViewMaterial, builtinData, result, needLinearToSRGB);
	GetSurfaceDataDebug(_DebugViewMaterial, surfaceData, result, needLinearToSRGB);
	GetBSDFDataDebug(_DebugViewMaterial, bsdfData, result, needLinearToSRGB); // TODO: This required to initialize all field from BSDFData...

	// TEMP!
	// For now, the final blit in the backbuffer performs an sRGB write
	// So in the meantime we apply the inverse transform to linear data to compensate.
	if (!needLinearToSRGB)
		result = SRGBToLinear(max(0, result));

	return float4(result, 0.0);
}

