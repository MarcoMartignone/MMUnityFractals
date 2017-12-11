using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Rendering;
#if UNITY_EDITOR
using UnityEditor;
#endif // UNITY_EDITOR

[ExecuteInEditMode]
public class Raymarcher : MonoBehaviour
{
    public Material m_material;
    public int m_scene;
    Material m_internal_material;
    Vector2 m_resolution_prev;
    Mesh m_quad;

    CommandBuffer m_cb_prepass;
    CommandBuffer m_cb_raymarch;
    CommandBuffer m_cb_show_steps;

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

    }

    void OnWillRenderObject()
    {
        UpdateMaterial();
    }

    void OnPreRender()
    {
        UpdateMaterial();
    }

    void UpdateMaterial()
    {
        if(m_internal_material == null) { return; }

        m_internal_material.SetFloat("_Scene", m_scene);

        var t = GetComponent<Transform>();
        var r = t.rotation;
        float angle;
        Vector3 axis;
        r.ToAngleAxis(out angle, out axis);
        m_internal_material.SetVector("_Position", t.position);
        m_internal_material.SetVector("_Rotation", new Vector4(axis.x, axis.y, axis.z, angle));
        m_internal_material.SetVector("_Scale", t.lossyScale);
    }

}
