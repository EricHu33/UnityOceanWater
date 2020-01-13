using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class MaterialApplier : MonoBehaviour
{
    public TextureData TextureData;
    // Start is called before the first frame update
    void Start()
    {
        TextureData.ApplyMaterial();
    }

    // Update is called once per frame
    void Update()
    {

    }
}
