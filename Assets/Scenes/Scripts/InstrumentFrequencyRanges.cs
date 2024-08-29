using UnityEngine;

[System.Serializable]
public class InstrumentFrequencyRanges
{
    public Vector2 kickFrequencyRange = new Vector2(20.0f, 100.0f);
    public Vector2 snareFrequencyRange = new Vector2(100.0f, 400.0f);
    public Vector2 hihatFrequencyRange = new Vector2(400.0f, 800.0f);
    public Vector2 bassFrequencyRange = new Vector2(80.0f, 300.0f);
    public Vector2 leadFrequencyRange = new Vector2(800.0f, 2000.0f);
}