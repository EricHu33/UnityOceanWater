using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class cammeraDepth : MonoBehaviour
{
    // Start is called before the first frame update
    void Awake()
    {
        GetComponent<Camera>().depthTextureMode = DepthTextureMode.Depth;
    }

    // Update is called once per frame
    void Update()
    {

    }
}
