using UnityEngine;
using System.Collections.Generic;

[ExecuteInEditMode]
public class CreateQuadAndAlign : MonoBehaviour
{
    public Camera mainCamera;
    public Material quadMaterial;

    [Header("Textures")]
    public List<Texture2D> textures2D = new List<Texture2D>();
    public List<Cubemap> cubemaps = new List<Cubemap>();

    [Header("Audio")]
    public bool useAudioVisualization = false;
    [Range(64, 8192)]
    public int fftResolution = 1024;
    [Range(2, 32)]
    public int Bands = 24;
    public float WaveScale = 0.5f;
    public float SpectrumScale = 0.2f;
    public FFTAlgorithm fftAlgorithm = FFTAlgorithm.RectangularFFT;
    
    [Header("Smoothing")]
    [Range(0.1f, 1.0f)]
    public float smoothFactor = 0.5f; // Smoothing factor for EMA
    
    // Instrument frequency ranges
    public InstrumentFrequencyRanges instrumentFrequencyRanges;
    
    // Fields for adjusting frequency ranges for each instrument
    [Header("Kick Frequency Range")]
    [Range(20.0f, 100.0f)]
    public float kickLow = 20.0f;
    [Range(20.0f, 200.0f)]
    public float kickHigh = 100.0f;

    [Header("Snare Frequency Range")]
    [Range(100.0f, 2500.0f)]
    public float snareLow = 100.0f;
    [Range(100.0f, 2500.0f)]
    public float snareHigh = 400.0f;

    [Header("Hihat Frequency Range")]
    [Range(400.0f, 5000.0f)]
    public float hihatLow = 400.0f;
    [Range(400.0f, 5000.0f)]
    public float hihatHigh = 800.0f;

    [Header("Bass Frequency Range")]
    [Range(80.0f, 300.0f)]
    public float bassLow = 80.0f;
    [Range(80.0f, 600.0f)]
    public float bassHigh = 300.0f;

    [Header("Lead Frequency Range")]
    [Range(800.0f, 8000.0f)]
    public float leadLow = 800.0f;
    [Range(800.0f, 8000.0f)]
    public float leadHigh = 2000.0f;

    private GameObject quad;
    private AudioSource audioSource;
    private float[] audioSpectrumRight;
    private float[] audioSpectrumLeft;
    private float[] audioSpectrum;
    private float[] audioWaveformLeft;
    private float[] audioWaveformRight;
    private float[] audioWaveform;
    private float[] instrumentAmplitudes;
    private float[] smoothedAudioSpectrum; // Smoothed audio spectrum data
    private float[] smoothedAudioWaveform; // Smoothed audio waveform data
    private const string quadName = "UniqueQuadName"; // Unique name for the quad

    public void EnableRendering()
    {
        if (quad != null)
        {
            quad.SetActive(true);  // Enable the quad and its rendering
        }
    }

    public void DisableRendering()
    {
        if (quad != null)
        {
            quad.SetActive(false);  // Disable the quad to stop rendering
        }
    }
    
    // Update the frequency ranges based on the sliders
    public void UpdateFrequencyRanges()
    {
        instrumentFrequencyRanges.kickFrequencyRange = new Vector2(kickLow, kickHigh);
        instrumentFrequencyRanges.snareFrequencyRange = new Vector2(snareLow, snareHigh);
        instrumentFrequencyRanges.hihatFrequencyRange = new Vector2(hihatLow, hihatHigh);
        instrumentFrequencyRanges.bassFrequencyRange = new Vector2(bassLow, bassHigh);
        instrumentFrequencyRanges.leadFrequencyRange = new Vector2(leadLow, leadHigh);
    }

    public enum FFTAlgorithm
    {
        RectangularFFT,
        HanningFFT,
        BlackmanFFT,
        BlackmanHarrisFFT,
        HammingFFT,
        // Add more FFT algorithms as needed
    }

    [System.Serializable]
    public struct InstrumentFrequencyRanges
    {
        public Vector2 kickFrequencyRange;
        public Vector2 snareFrequencyRange;
        public Vector2 hihatFrequencyRange;
        public Vector2 bassFrequencyRange;
        public Vector2 leadFrequencyRange;
    }

    void Start()
    {
        InitializeAudioArrays();
        // Get the AudioSource from AudioManager
        audioSource = AudioManager.Instance.MasterAudioSource;
    }

    void OnEnable()
    {
        if (mainCamera == null)
        {
            mainCamera = Camera.main;
        }

        // Create or reposition the quad
        CreateOrRepositionQuad();
    }

    void Update()
    {
        // Update shader properties if quad exists
        if (quad)
        {
            UpdateShaderProperties();
        }
        else
        {
            CreateOrRepositionQuad();
            UpdateShaderProperties();
        }
    }

    void CreateOrRepositionQuad()
    {
        // Ensure quad exists or create it
        quad = GameObject.Find(quadName);
        if (quad == null)
        {
            CreateQuad();
        }

        // Position and scale the quad
        AlignQuadWithScreen();
    }

    void CreateQuad()
    {
        quad = new GameObject(quadName);
        MeshFilter meshFilter = quad.AddComponent<MeshFilter>();
        MeshRenderer meshRenderer = quad.AddComponent<MeshRenderer>();

        meshFilter.mesh = CreateQuadMesh();
        meshRenderer.material = quadMaterial;
    }

    Mesh CreateQuadMesh()
    {
        Mesh mesh = new Mesh();

        // Define quad vertices
        Vector3[] vertices = new Vector3[4];
        vertices[0] = new Vector3(-0.5f, -0.5f, 0); // Bottom left
        vertices[1] = new Vector3(0.5f, -0.5f, 0); // Bottom right
        vertices[2] = new Vector3(-0.5f, 0.5f, 0); // Top left
        vertices[3] = new Vector3(0.5f, 0.5f, 0); // Top right

        // Define quad triangles
        int[] triangles = new int[6] { 0, 2, 1, 1, 2, 3 };

        // Define UVs
        Vector2[] uvs = new Vector2[4];
        uvs[0] = new Vector2(0, 0); // Bottom left
        uvs[1] = new Vector2(1, 0); // Bottom right
        uvs[2] = new Vector2(0, 1); // Top left
        uvs[3] = new Vector2(1, 1); // Top right

        // Assign vertices, triangles, and UVs to the mesh
        mesh.vertices = vertices;
        mesh.triangles = triangles;
        mesh.uv = uvs;

        return mesh;
    }

    void AlignQuadWithScreen()
    {
        if (quad == null || mainCamera == null)
            return;

        // Calculate screen dimensions
        float distanceFromCamera = mainCamera.nearClipPlane + 0.01f; // Small offset from the near clip plane
        float frustumHeight = 2.0f * distanceFromCamera * Mathf.Tan(mainCamera.fieldOfView * 0.5f * Mathf.Deg2Rad);
        float frustumWidth = frustumHeight * mainCamera.aspect;

        // Position the quad in front of the camera
        quad.transform.position = mainCamera.transform.position + mainCamera.transform.forward * distanceFromCamera;

        // Rotate the quad to face the camera
        quad.transform.rotation = mainCamera.transform.rotation;

        // Scale the quad to fit the screen size
        quad.transform.localScale = new Vector3(frustumWidth, frustumHeight, 1.0f);
    }

    void InitializeAudioArrays()
    {
        audioSpectrum = new float[fftResolution];
        audioSpectrumRight = new float[fftResolution];
        audioSpectrumLeft = new float[fftResolution];
        audioWaveform = new float[fftResolution];
        audioWaveformRight = new float[fftResolution];
        audioWaveformLeft = new float[fftResolution];
        smoothedAudioSpectrum = new float[fftResolution]; // Initialize smoothed array
        smoothedAudioWaveform = new float[fftResolution]; // Initialize smoothed waveform array
        instrumentFrequencyRanges = new InstrumentFrequencyRanges();
        instrumentAmplitudes = new float[5];
    }

    public void SetAudioSource(AudioSource source)
    {
        audioSource = source;
    }

    public AudioSource GetAudioSource()
    {
        return audioSource;
    }

    void UpdateShaderProperties()
    {
        if (quadMaterial)
        {
            if (useAudioVisualization)
            {
                
                UpdateFrequencyRanges();
                GetAudioSpectrum();
                SmoothAudioSpectrum(); // Smooth the audio spectrum data
                SmoothAudioWaveform(); // Smooth the audio waveform data
            }

            // Update _iResolution based on the screen size
            quadMaterial.SetVector("_iResolution", new Vector4(Screen.width, Screen.height, 0.0f, 0.0f));
            quadMaterial.SetFloat("_MyTime", Time.time);
            quadMaterial.SetInt("_Bands", Bands);
            quadMaterial.SetFloat("_SpectrumScale", SpectrumScale);
            quadMaterial.SetFloat("_WaveFormScale", WaveScale);
            quadMaterial.SetFloatArray("_AudioSpectrum", smoothedAudioSpectrum); // Pass smoothed data to shader
            quadMaterial.SetFloatArray("_AudioWaveform", smoothedAudioWaveform); // Pass smoothed waveform to shader
            quadMaterial.SetFloatArray("_InstrumentAmplitudes", instrumentAmplitudes); // Pass instrument amplitudes to shader

            // Update the textures and cubemaps in the shader
            for (int i = 0; i < textures2D.Count && i < 10; i++)
            {
                quadMaterial.SetTexture("_Texture2D" + i, textures2D[i]);
            }

            for (int i = 0; i < cubemaps.Count && i < 5; i++)
            {
                quadMaterial.SetTexture("_Cubemap" + i, cubemaps[i]);
            }
        }
    }

    void GetAudioSpectrum()
    {
        if (!audioSource || !audioSource.clip) return;

        var alg = FFTWindow.Rectangular;
        // Apply FFT based on selected algorithm
        switch (fftAlgorithm)
        {
            case FFTAlgorithm.RectangularFFT:
                alg = FFTWindow.Rectangular;
                break;
            case FFTAlgorithm.HanningFFT:
                alg = FFTWindow.Hanning;
                break;
            case FFTAlgorithm.BlackmanFFT:
                alg = FFTWindow.Blackman;
                break;
            case FFTAlgorithm.BlackmanHarrisFFT:
                alg = FFTWindow.BlackmanHarris;
                break;
            case FFTAlgorithm.HammingFFT:
                alg = FFTWindow.Hamming;
                break;
            default:
                Debug.LogWarning("Unsupported FFT algorithm selected.");
                break;
        }
        if (audioSource.isPlaying)
        {
            audioSource.GetSpectrumData(audioSpectrumRight, 0, alg);
            audioSource.GetSpectrumData(audioSpectrumLeft, 1, alg);
            audioSource.GetOutputData(audioWaveformRight, 0);
            audioSource.GetOutputData(audioWaveformLeft, 1);

            // Combine stereo channels into mono
            for (int i = 0; i < fftResolution; i++)
            {
                audioSpectrum[i] = (audioSpectrumRight[i] + audioSpectrumLeft[i]) * 0.5f;
                audioWaveform[i] = (audioWaveformRight[i] + audioWaveformLeft[i]) * 0.5f;
            }
            UpdateInstrumentAmplitudes();
        }
        else
        {
            Debug.Log("Audio source is not playing.");
        }
    }

    void UpdateInstrumentAmplitudes()
    {
        // Get the sample rate from the audio clip
        int sampleRate = audioSource.clip.frequency;

        // Calculate frequency per bin
        float freqPerBin = sampleRate / (float)fftResolution;

        // Convert frequency ranges to bin indices
        int kickLow = Mathf.FloorToInt(instrumentFrequencyRanges.kickFrequencyRange.x / freqPerBin);
        int kickHigh = Mathf.FloorToInt(instrumentFrequencyRanges.kickFrequencyRange.y / freqPerBin);
        int snareLow = Mathf.FloorToInt(instrumentFrequencyRanges.snareFrequencyRange.x / freqPerBin);
        int snareHigh = Mathf.FloorToInt(instrumentFrequencyRanges.snareFrequencyRange.y / freqPerBin);
        int hihatLow = Mathf.FloorToInt(instrumentFrequencyRanges.hihatFrequencyRange.x / freqPerBin);
        int hihatHigh = Mathf.FloorToInt(instrumentFrequencyRanges.hihatFrequencyRange.y / freqPerBin);
        int bassLow = Mathf.FloorToInt(instrumentFrequencyRanges.bassFrequencyRange.x / freqPerBin);
        int bassHigh = Mathf.FloorToInt(instrumentFrequencyRanges.bassFrequencyRange.y / freqPerBin);
        int leadLow = Mathf.FloorToInt(instrumentFrequencyRanges.leadFrequencyRange.x / freqPerBin);
        int leadHigh = Mathf.FloorToInt(instrumentFrequencyRanges.leadFrequencyRange.y / freqPerBin);

        // Update the spectrum data
        audioSource.GetSpectrumData(audioSpectrum, 0, FFTWindow.BlackmanHarris);

        // Calculate amplitudes for each instrument
        instrumentAmplitudes[0] = CalculateAmplitude(kickLow, kickHigh);
        instrumentAmplitudes[1] = CalculateAmplitude(snareLow, snareHigh);
        instrumentAmplitudes[2] = CalculateAmplitude(hihatLow, hihatHigh);
        instrumentAmplitudes[3] = CalculateAmplitude(bassLow, bassHigh);
        instrumentAmplitudes[4] = CalculateAmplitude(leadLow, leadHigh);
    }

    float CalculateAmplitude(int lowIndex, int highIndex)
    {
        int frequencies = 0;
        float amplitude = 0.0f;
        for (int i = lowIndex; i <= highIndex; i++)
        {
            amplitude += audioSpectrum[i];
            frequencies++;
        }
        return frequencies > 0 ? amplitude / frequencies : 0.0f;
    }

    void SmoothAudioSpectrum()
    {
        // Apply EMA smoothing to the audio spectrum data
        for (int i = 0; i < fftResolution; i++)
        {
            smoothedAudioSpectrum[i] = Mathf.Lerp(smoothedAudioSpectrum[i], audioSpectrum[i], smoothFactor);
        }
    }

    void SmoothAudioWaveform()
    {
        // Apply EMA smoothing to the audio waveform data
        for (int i = 0; i < fftResolution; i++)
        {
            smoothedAudioWaveform[i] = Mathf.Lerp(smoothedAudioWaveform[i], audioWaveform[i], smoothFactor);
        }
    }

    void Awake()
    {
        InitializeAudioArrays();
        if (Application.isPlaying)
        {
            audioSource = AudioManager.Instance.MasterAudioSource;
        }
    }

    void OnDisable()
    {
        // Destroy the quad when the script is disabled or destroyed
        if (quad != null)
        {
            DestroyImmediate(quad);
            quad = null;
        }
    }
}
