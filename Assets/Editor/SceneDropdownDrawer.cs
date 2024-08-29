using UnityEditor;
using UnityEngine;

[CustomPropertyDrawer(typeof(SceneDropdownAttribute))]
public class SceneDropdownDrawer : PropertyDrawer
{
    public override void OnGUI(Rect position, SerializedProperty property, GUIContent label)
    {
        if (property.propertyType == SerializedPropertyType.String)
        {
            var scenes = EditorBuildSettings.scenes;
            var sceneNames = new string[scenes.Length];

            for (int i = 0; i < scenes.Length; i++)
            {
                sceneNames[i] = System.IO.Path.GetFileNameWithoutExtension(scenes[i].path);
            }

            int index = Mathf.Max(System.Array.IndexOf(sceneNames, property.stringValue), 0);
            index = EditorGUI.Popup(position, label.text, index, sceneNames);
            property.stringValue = sceneNames[index];
        }
        else
        {
            EditorGUI.PropertyField(position, property, label);
        }
    }
}