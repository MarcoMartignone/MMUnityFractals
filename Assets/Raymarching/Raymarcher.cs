using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Rendering;
#if UNITY_EDITOR
using UnityEditor;
#endif // UNITY_EDITOR


public static class RaymarcherUtils
{
    public static Mesh GenerateQuad()
    {
        Vector3[] vertices = new Vector3[4] {
                new Vector3( 1.0f, 1.0f, 0.0f),
                new Vector3(-1.0f, 1.0f, 0.0f),
                new Vector3(-1.0f,-1.0f, 0.0f),
                new Vector3( 1.0f,-1.0f, 0.0f),
            };
        int[] indices = new int[6] { 0, 1, 2, 2, 3, 0 };

        Mesh r = new Mesh();
        r.vertices = vertices;
        r.triangles = indices;
        return r;
    }

    public static Mesh GenerateDetailedQuad()
    {
        const int div_x = 325;
        const int div_y = 200;

        var cell = new Vector2(2.0f / div_x, 2.0f / div_y);
        var vertices = new Vector3[65000];
        var indices = new int[(div_x-1)*(div_y-1)*6];
        for (int iy = 0; iy < div_y; ++iy)
        {
            for (int ix = 0; ix < div_x; ++ix)
            {
                int i = div_x * iy + ix;
                vertices[i] = new Vector3(cell.x * ix - 1.0f, cell.y * iy - 1.0f, 0.0f);
            }
        }
        for (int iy = 0; iy < div_y-1; ++iy)
        {
            for (int ix = 0; ix < div_x-1; ++ix)
            {
                int i = ((div_x-1) * iy + ix)*6;
                indices[i + 0] = (div_x * (iy + 1)) + (ix + 1);
                indices[i + 1] = (div_x * (iy + 0)) + (ix + 1);
                indices[i + 2] = (div_x * (iy + 0)) + (ix + 0);

                indices[i + 3] = (div_x * (iy + 0)) + (ix + 0);
                indices[i + 4] = (div_x * (iy + 1)) + (ix + 0);
                indices[i + 5] = (div_x * (iy + 1)) + (ix + 1);
            }
        }

        Mesh r = new Mesh();
        r.vertices = vertices;
        r.triangles = indices;
        return r;
    }
}

[ExecuteInEditMode]
public class Raymarcher : MonoBehaviour
{
    public Material m_material;
    public int m_scene;
    public Color m_fog_color = new Color(0.16f, 0.13f, 0.20f);
    Material m_internal_material;
    Vector2 m_resolution_prev;
    Mesh m_quad;

    CommandBuffer m_cb_prepass;
    CommandBuffer m_cb_raymarch;
    CommandBuffer m_cb_show_steps;

    bool m_enable_adaptive_prev;
    bool m_dbg_show_steps_prev;

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

    void ClearCommandBuffer()
    {
        var cam = GetComponent<Camera>();
        if (cam != null)
        {
            if (m_cb_prepass != null)
            {
                cam.RemoveCommandBuffer(CameraEvent.BeforeGBuffer, m_cb_prepass);
            }
            if (m_cb_raymarch != null)
            {
                cam.RemoveCommandBuffer(CameraEvent.BeforeGBuffer, m_cb_raymarch);
            }
            if (m_cb_show_steps != null)
            {
                cam.RemoveCommandBuffer(CameraEvent.AfterEverything, m_cb_show_steps);
            }
            m_cb_prepass = null;
            m_cb_raymarch = null;
            m_cb_show_steps = null;
        }
    }

    void OnDisable()
    {
        ClearCommandBuffer();
    }

    void OnWillRenderObject()
    {
        UpdateMaterial();
    }

    void OnPreRender()
    {
        UpdateMaterial();
        UpdateCommandBuffer();
    }

    void SwitchKeyword(Material m, string name, bool v)
    {
        if(v) { m.EnableKeyword(name); }
        else  { m.DisableKeyword(name); }
    }

    void UpdateMaterial()
    {
        if(m_internal_material == null) { return; }

        var t = GetComponent<Transform>();
        var r = t.rotation;
        float angle;
        Vector3 axis;
        r.ToAngleAxis(out angle, out axis);
        m_internal_material.SetVector("_Position", t.position);
        m_internal_material.SetVector("_Rotation", new Vector4(axis.x, axis.y, axis.z, angle));
        m_internal_material.SetVector("_Scale", t.lossyScale);
    }

    void UpdateCommandBuffer()
    {
        var cam = GetComponent<Camera>();

        RenderSettings.fogColor = m_fog_color;

        if (m_quad == null)
        {
            m_quad = RaymarcherUtils.GenerateQuad();
        }

        bool reflesh_command_buffer = false;

        Vector2 reso = new Vector2(cam.pixelWidth, cam.pixelHeight);
        if(m_resolution_prev!=reso)
        {
            m_resolution_prev = reso;
            reflesh_command_buffer = true;
        }

        if (reflesh_command_buffer)
        {
            reflesh_command_buffer = false;
            ClearCommandBuffer();
        }

        if (m_cb_raymarch==null)
        {
            m_cb_raymarch = new CommandBuffer();
            m_cb_raymarch.name = "Raymarcher";
            m_cb_raymarch.DrawMesh(m_quad, Matrix4x4.identity, m_internal_material, 0, 0);
            cam.AddCommandBuffer(CameraEvent.BeforeGBuffer, m_cb_raymarch);
        }
    }
}
