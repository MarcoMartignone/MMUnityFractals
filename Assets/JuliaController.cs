using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEditor;

public class JuliaController : MonoBehaviour
{

    [Range (0, 10)]
    public float _threshold = 0.0f;

    void OnStart()
    {



    }

    private void OnValidate()
    {
        Shader.SetGlobalFloat("_threshold", _threshold);
    }

}
