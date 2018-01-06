using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Rendering;
#if UNITY_EDITOR
using UnityEditor;
#endif

[ExecuteInEditMode]
public class Octahedron : MonoBehaviour
{
    public Material m_material;
    Material m_internal_material;

	public float Scale = 1.53332f;
	public Vector3 Offset = new Vector3(0.48246f, 0.09649f, 0.15789f);
	public float Angle1 = -119.99900f;
	public Vector3 Rot1 = new Vector3(1.00000f, -0.50850f, 0.44068f);
	public float Angle2 = 29.99880f;
	public Vector3 Rot2 = new Vector3(0.50848f, 1.00000f, -0.62800f);
	public float val = 0;
	public float cylRad = 0.10000f;
	public float cylHeight = 2.00000f;
	public Vector3 O3 = new Vector3(1, 1, 1);
	public float Iterations = 26;
	public float ColorIterations = 2;


#if UNITY_EDITOR
    void Reset()
    {
        m_material = AssetDatabase.LoadAssetAtPath<Material>("Assets/Raymarching/Raymarcher.mat");
    }
#endif // UNITY_EDITOR

    void Awake()
    {
#if UNITY_EDITOR
        var cam = GetComponent<Camera>();
        if (cam !=null &&
            cam.renderingPath != RenderingPath.DeferredShading &&
            (cam.renderingPath == RenderingPath.UsePlayerSettings && PlayerSettings.renderingPath != RenderingPath.DeferredShading))
        {
            Debug.Log("Raymarcher: Rendering path must be deferred.");
        }
#endif // UNITY_EDITOR

        m_internal_material = new Material(m_material);
        var r = GetComponent<Renderer>();
        if (r != null) { r.sharedMaterial = m_internal_material; }

        UpdateMaterial();

    }

    void OnWillRenderObject()
    {
        UpdateMaterial();
        Debug.Log("WILL RENDER");
    }

    void OnPreRender()
    {
        UpdateMaterial();
        Debug.Log("PRE RENDER");
    }

    void UpdateMaterial()
    {
        if(m_internal_material == null) { return; }

        m_internal_material.SetFloat("_Scale", Scale);
		m_internal_material.SetVector("_Offset", Offset);
		m_internal_material.SetFloat("_Angle1", Angle1);
		m_internal_material.SetVector("_Rot1", Rot1);
		m_internal_material.SetFloat("_Angle2", Angle2);
		m_internal_material.SetVector("_Rot2", Rot2);
		m_internal_material.SetFloat("_val", val);
		m_internal_material.SetFloat("_cylRad", cylRad);
		m_internal_material.SetFloat("_cylHeight", cylHeight);
		m_internal_material.SetVector("_O3", O3);
		m_internal_material.SetFloat("_Iterations", Iterations);
		m_internal_material.SetFloat("_ColorIterations", ColorIterations);

        Debug.Log("UPDATING MATERIAL");
		
    }

}
