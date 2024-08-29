using System.Collections;
using UnityEngine;
using UnityEngine.SceneManagement;
using UnityEngine.UI;

public class SceneSwitcher : MonoBehaviour
{
    public bool debugMode = false;

    [SceneDropdown]
    public string debugSceneName = "";

    [SceneDropdown]
    public string[] scenes;  // Use SceneDropdown on each element in the array
    public float[] sceneTimes;       // Duration for each scene
    public int currentSceneIndex = 0;
    public float fadeDuration = 1.0f;
    public Image fadeImage;
    private AudioSource masterAudioSource;
    private string activeSceneName;
    private CreateQuadAndAlign currentEffectPlumbing;

    void Start()
    {
        // Get the audio source from the AudioManager
        masterAudioSource = AudioManager.Instance.MasterAudioSource;
        fadeImage.color = Color.black;

        if (debugMode && !string.IsNullOrEmpty(debugSceneName))
        {
            // Load the debug scene only
            activeSceneName = debugSceneName;
            StartCoroutine(LoadSceneAsync(debugSceneName, true));
            
            // Ensure that the fadeImage is transparent when debugging
            fadeImage.color = new Color(0.0f, 0.0f, 0.0f, 0.0f);
        }
        else
        {
            // Load the first scene in the list normally
            activeSceneName = scenes[currentSceneIndex];
            StartCoroutine(StartFirstScene());
        }
        DontDestroyOnLoad(this.gameObject);  // Persist across scene loads
        masterAudioSource.Play();
    }

    IEnumerator StartFirstScene()
    {
        // Load the first scene
        yield return StartCoroutine(LoadSceneAsync(activeSceneName, true));

        // Fade in the first scene
        yield return StartCoroutine(FadeIn());

        // Now start the scene control loop
        StartCoroutine(SceneControl());
    }

    IEnumerator FadeIn()
    {
        float t = 1.0f;
        while (t > 0.0f)
        {
            t -= Time.deltaTime / fadeDuration;
            fadeImage.color = new Color(0.0f, 0.0f, 0.0f, t);
            yield return null;
        }
    }

    IEnumerator FadeOut()
    {
        float t = 0.0f;
        while (t < 1.0f)
        {
            t += Time.deltaTime / fadeDuration;
            fadeImage.color = new Color(0.0f, 0.0f, 0.0f, t);
            yield return null;
        }
    }

    IEnumerator SceneControl()
    {
        while (true)
        {
            // Wait for the scene time before fading out
            yield return new WaitForSeconds(sceneTimes[currentSceneIndex]);
            yield return StartCoroutine(FadeOut());

            // Move to the next scene in the list
            int previousSceneIndex = currentSceneIndex;
            currentSceneIndex++;
            if (currentSceneIndex >= scenes.Length)
            {
                // End the application when the last scene is reached
                #if UNITY_EDITOR
                UnityEditor.EditorApplication.isPlaying = false;
                #else
                Application.Quit();
                #endif

                yield break; // Ensure no further code is executed
            }

            string nextSceneName = scenes[currentSceneIndex];
            yield return StartCoroutine(LoadSceneAsync(nextSceneName, false));

            // Unload the previous scene after the new one has fully loaded
            if (previousSceneIndex != currentSceneIndex)
            {
                SceneManager.UnloadSceneAsync(scenes[previousSceneIndex]);
            }

            yield return StartCoroutine(FadeIn());
        }
    }

    IEnumerator LoadSceneAsync(string sceneName, bool isInitialLoad)
    {
        // Load the scene asynchronously in the background
        AsyncOperation asyncLoad = SceneManager.LoadSceneAsync(sceneName, LoadSceneMode.Additive);
        asyncLoad.allowSceneActivation = true;

        // Wait until the scene is fully loaded
        while (!asyncLoad.isDone)
        {
            yield return null;
        }
        Scene loadedScene = SceneManager.GetSceneByName(sceneName);
        if (loadedScene.IsValid())
        {
            // Find the root GameObjects in the loaded scene
            GameObject[] rootGameObjects = loadedScene.GetRootGameObjects();

            // Iterate through the root objects to find the CreateQuadAndAlign script
            foreach (GameObject rootGameObject in rootGameObjects)
            {
                currentEffectPlumbing = rootGameObject.GetComponentInChildren<CreateQuadAndAlign>();
                if (currentEffectPlumbing)
                {
                    // Reattach the master audio source
                    currentEffectPlumbing.SetAudioSource(masterAudioSource);

                    // Enable rendering and ensure everything is properly initialized
                    currentEffectPlumbing.EnableRendering();
                    break; // Exit loop once the component is found
                }
            }
        }

        if (!isInitialLoad)
        {
            // Optionally delay to let the scene fully initialize if needed
            yield return new WaitForSeconds(0.5f);
        }

        // Update the active scene name
        activeSceneName = sceneName;
    }
}
