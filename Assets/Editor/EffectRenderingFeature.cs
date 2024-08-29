using UnityEngine;
using UnityEditor;
using System.Collections.Generic;

[CustomEditor(typeof(CreateQuadAndAlign))]
public class CreateQuadAndAlignEditor : Editor
{
    public override void OnInspectorGUI()
    {
        DrawDefaultInspector();

        CreateQuadAndAlign script = (CreateQuadAndAlign)target;

        // Button to add new Texture2D
        if (GUILayout.Button("Add Texture2D"))
        {
            script.textures2D.Add(null);
        }

        // Display and manage the Texture2D list
        for (int i = 0; i < script.textures2D.Count; i++)
        {
            EditorGUILayout.BeginHorizontal();
            script.textures2D[i] = (Texture2D)EditorGUILayout.ObjectField("Texture2D " + i, script.textures2D[i], typeof(Texture2D), false);
            if (GUILayout.Button("Remove"))
            {
                script.textures2D.RemoveAt(i);
            }
            EditorGUILayout.EndHorizontal();
        }

        // Button to add new Cubemap
        if (GUILayout.Button("Add Cubemap"))
        {
            script.cubemaps.Add(null);
        }

        // Display and manage the Cubemap list
        for (int i = 0; i < script.cubemaps.Count; i++)
        {
            EditorGUILayout.BeginHorizontal();
            script.cubemaps[i] = (Cubemap)EditorGUILayout.ObjectField("Cubemap " + i, script.cubemaps[i], typeof(Cubemap), false);
            if (GUILayout.Button("Remove"))
            {
                script.cubemaps.RemoveAt(i);
            }
            EditorGUILayout.EndHorizontal();
        }

        EditorGUILayout.Space();
        EditorGUILayout.LabelField("Audio Settings", EditorStyles.boldLabel);

        // Toggle for using audio visualization
        script.useAudioVisualization = EditorGUILayout.Toggle("Use Audio Visualization", script.useAudioVisualization);

        // FFT algorithm dropdown menu
        script.fftAlgorithm = (CreateQuadAndAlign.FFTAlgorithm)EditorGUILayout.EnumPopup("FFT Algorithm", script.fftAlgorithm);

        // FFT resolution slider
        script.fftResolution = EditorGUILayout.IntSlider("FFT Resolution", script.fftResolution, 64, 8192);

        // Bands slider
        script.Bands = EditorGUILayout.IntSlider("Bands", script.Bands, 2, 128);
        script.SpectrumScale = EditorGUILayout.Slider("Spectrum Scale", script.SpectrumScale, 0.1f, 3.0f);
        script.WaveScale = EditorGUILayout.Slider("Wave Scale", script.WaveScale, 0.1f, 3.0f);
    }
}
