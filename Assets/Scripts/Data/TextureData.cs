using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using System.Linq;
using System;

[CreateAssetMenu()]
public class TextureData : UpdatableData
{
    [Serializable]
    public class Layer
    {
        public Texture2D Texture;
        public float Scale;
        public Color TintColor;
        [Range(0, 1)]
        public float BaseStartHeight;
        [Range(0, 1)]
        public float BaseBlend;
    }

    const int TEXTURE_SIZE = 512;
    const TextureFormat textureFormat = TextureFormat.RGB565;

    public Layer[] Layers;
    private float savedMinHeight;
    private float savedMaxHeight;
    public Material Material;

    public void ApplyMaterial()
    {
        Material.SetInt("baseColorCount", Layers.Length);
        Material.SetColorArray("tintColors", Layers.Select(e => e.TintColor).ToArray());
        Material.SetFloatArray("baseStartHeights", Layers.Select(e => e.BaseStartHeight).ToArray());
        Material.SetTexture("baseTextures", GenerateTextureArray(Layers.Select(e => e.Texture).ToArray()));
        Material.SetFloatArray("baseTextureScales", Layers.Select(e => e.Scale).ToArray());
        Material.SetFloatArray("baseBlends", Layers.Select(e => e.BaseBlend).ToArray());
        UpdateMeshHeights(savedMinHeight, savedMaxHeight);
    }

    private Texture2DArray GenerateTextureArray(Texture2D[] textures)
    {
        Texture2DArray textureArray = new Texture2DArray(TEXTURE_SIZE, TEXTURE_SIZE, textures.Length, textureFormat, true);
        {
            for (int i = 0; i < textures.Length; i++)
            {
                textureArray.SetPixels(textures[i].GetPixels(), i);
            }
            textureArray.Apply();
        }
        return textureArray;
    }


    public void UpdateMeshHeights(float minHeight, float maxHeight)
    {
        savedMinHeight = minHeight;
        savedMaxHeight = maxHeight;
        Material.SetFloat("minHeight", minHeight);
        Material.SetFloat("maxHeight", maxHeight);
    }

    protected override void OnValidate()
    {
        base.OnValidate();
    }
}
