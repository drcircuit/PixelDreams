using UnityEngine;

public class AudioManager : MonoBehaviour
{
    private static AudioManager _instance;
    public static AudioManager Instance
    {
        get
        {
            if (_instance == null)
            {
                _instance = FindObjectOfType<AudioManager>();
                if (_instance == null)
                {
                    GameObject obj = new GameObject("AudioManager");
                    _instance = obj.AddComponent<AudioManager>();
                }
                // check if we are in Play mode or not
                if (Application.isPlaying)
                {
                    DontDestroyOnLoad(_instance.gameObject);
                }
            }
            return _instance;
        }
    }

    [Header("Audio Settings")]
    public AudioClip audioClip;
    public float volume = 1.0f;
    public bool loop = true;
    public float pitch = 1.0f;

    public AudioSource MasterAudioSource { get; private set; }

    void Awake()
    {
        if (_instance != null && _instance != this)
        {
            Destroy(gameObject);
            return;
        }

        _instance = this;
        DontDestroyOnLoad(gameObject);

        SetupAudioSource();
    }

    private void SetupAudioSource()
    {
        MasterAudioSource = GetComponent<AudioSource>();
        if (MasterAudioSource == null)
        {
            MasterAudioSource = gameObject.AddComponent<AudioSource>();
        }

        // Apply initial settings from the inspector
        if (audioClip != null)
        {
            MasterAudioSource.clip = audioClip;
        }
        MasterAudioSource.volume = volume;
        MasterAudioSource.loop = loop;
        MasterAudioSource.pitch = pitch;
    }

    public void SetAudioClip(AudioClip clip)
    {
        if (MasterAudioSource != null)
        {
            MasterAudioSource.clip = clip;
        }
    }

    public void Play()
    {
        if (MasterAudioSource != null && MasterAudioSource.clip != null)
        {
            MasterAudioSource.Play();
        }
    }

    public void Stop()
    {
        if (MasterAudioSource != null)
        {
            MasterAudioSource.Stop();
        }
    }

    public void SetVolume(float volume)
    {
        if (MasterAudioSource != null)
        {
            MasterAudioSource.volume = volume;
        }
    }

    public void SetLoop(bool loop)
    {
        if (MasterAudioSource != null)
        {
            MasterAudioSource.loop = loop;
        }
    }

    public void SetPitch(float pitch)
    {
        if (MasterAudioSource != null)
        {
            MasterAudioSource.pitch = pitch;
        }
    }

    public bool IsPlaying()
    {
        return MasterAudioSource != null && MasterAudioSource.isPlaying;
    }
}
