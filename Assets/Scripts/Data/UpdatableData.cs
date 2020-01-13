using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class UpdatableData : ScriptableObject
{
    public System.Action OnValueUpdated;
    public bool AutoUpdate;

    protected virtual void OnValidate()
    {
        if (AutoUpdate)
        {
            Notify();
        }
    }

    public void Notify()
    {
        OnValueUpdated?.Invoke();
    }
}
