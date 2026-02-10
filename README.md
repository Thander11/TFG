# Estudio de viabilidad de una Nariz Electrónica como herramienta de apoyo para los Agentes Caninos

**Autor:** Raúl Martín-Romo Sánchez  
**Grado:** Grado en Ingeniería Informática del Software  
**Tutor:** Pablo García Rodríguez  
**Co-tutor:** Jesús Lozano Rogado  
**Universidad de Extremadura - Escuela Politécnica de Cáceres**

---

## 📄 Documentación

El documento completo del Trabajo Fin de Grado está disponible en este repositorio:
- [TFG - Estudio de viabilidad de una Nariz Electrónica como herramienta de apoyo para los Agentes Caninos.pdf](TFG%20-%20Estudio%20de%20viabilidad%20de%20una%20Nariz%20Electrónica%20como%20herramienta%20de%20apoyo%20para%20los%20Agentes%20Caninos.pdf)

---

## 🎯 Resumen del Proyecto

Este Trabajo Fin de Grado aborda el desarrollo y evaluación de una nariz electrónica (e-nose) como herramienta complementaria para los agentes caninos del cuerpo de detección de sustancias de la Guardia Civil. El proyecto combina técnicas de ingeniería electrónica, procesamiento de señales y machine learning para crear un sistema capaz de detectar sustancias específicas.

## 💡 Idea del Proyecto

Desarrollar una nariz electrónica capaz de detectar un tipo de sustancia y compararla con el olfato de los agentes caninos entrenados del cuerpo de detección de sustancias de la Guardia Civil.

## 🌟 Motivación

Las principales motivaciones de este trabajo son las siguientes:

- **Admiración** por el trabajo de las unidades caninas de los cuerpos de seguridad y su labor en la detección de sustancias.
- **Apoyo tecnológico** para facilitar y mejorar el trabajo de los cuerpos caninos, proporcionando una herramienta complementaria.
- **Reducción de carga de trabajo** cuando la demanda sea excesiva o las condiciones no sean óptimas para los agentes caninos.
- **Disponibilidad continua** ofreciendo una alternativa en situaciones donde los agentes caninos no estén disponibles.

## 🎯 Objetivos

Los objetivos principales del proyecto son:

1. **Estudio teórico**: Investigación de la nariz electrónica, su funcionamiento, componentes y diferentes aplicaciones en diversos campos.
2. **Desarrollo del sistema**: Diseño e implementación de una nariz electrónica utilizando sensores de óxidos metálicos (MOX).
3. **Entrenamiento del sistema**: Formación y calibración de la nariz electrónica para la detección específica de sustancias objetivo.
4. **Comparativa con agentes caninos**: Evaluación comparativa del rendimiento de la nariz electrónica frente al olfato de los agentes caninos entrenados.
5. **Análisis de viabilidad**: Estudio de la viabilidad técnica, económica y operativa de la nariz electrónica como herramienta de apoyo.

Se busca crear una nariz electrónica que, aunque no iguale el rendimiento de los agentes caninos, ofrezca una ayuda viable en términos de **costo**, **mantenimiento** y **disponibilidad**.

## 🔧 Materiales y Tecnología

### Hardware
- **Sensores MOX** (Sensores de óxidos metálicos semiconductores)
- Placa de desarrollo para procesamiento de señales
- Sistema de muestreo y cámara de sensores
- Componentes electrónicos adicionales para acondicionamiento de señal

### Software
- **Aplicación móvil**: Desarrollo de una aplicación Android (Sniffer) para la visualización y control del sistema
- **Algoritmos de ML**: Implementación de algoritmos de machine learning para el reconocimiento de patrones
- **Procesamiento de señales**: Técnicas de análisis y preprocesamiento de datos de los sensores

## 📱 Aplicación Sniffer

Este repositorio incluye el código fuente y la aplicación compilada de **Sniffer**, una aplicación móvil desarrollada en Flutter para Android que permite:

- Conexión con la nariz electrónica vía Bluetooth
- Visualización en tiempo real de las lecturas de los sensores
- Registro y almacenamiento de datos de muestreo
- Interfaz intuitiva para el operador

### Instalación
Descarga el archivo [Sniffer.apk](Sniffer.apk) e instálalo en tu dispositivo Android.

## 📊 Resultados Esperados

Tras la finalización del proyecto se espera obtener:

1. Una **nariz electrónica funcional** capaz de detectar tipos específicos de sustancias.
2. **Datos comparativos** del rendimiento entre la nariz electrónica y los agentes caninos.
3. **Evaluación de viabilidad** que determine las fortalezas y limitaciones del sistema desarrollado.
4. Una herramienta que, aunque no sustituya completamente a los agentes caninos, pueda ofrecer:
   - ✅ **Menor costo operativo** a largo plazo
   - ✅ **Menor necesidad de mantenimiento** comparado con el cuidado animal
   - ✅ **Mayor disponibilidad** sin necesidad de descanso
   - ✅ **Complemento efectivo** en situaciones de alta demanda

Se espera que el olfato canino siga siendo superior en términos de **precisión** y **rapidez**, pero la nariz electrónica podría ofrecer ventajas significativas como herramienta de apoyo, sin pretender ser una sustitución total de los miembros de este cuerpo especializado.

## 📂 Estructura del Repositorio

```
TFG/
├── Apuntes/              # Notas y apuntes del desarrollo
├── Documentación/        # Documentación técnica del proyecto en LaTeX
├── Entrenamiento/        # Scripts y datos de entrenamiento del modelo
├── Organización/         # Planificación y organización del proyecto
├── Presentación/         # Material para la defensa del TFG
├── Sniffer/              # Código fuente de la aplicación móvil
├── Sniffer.apk           # Aplicación Android compilada
├── DATOS.txt             # Datos de pruebas y experimentos
└── README.md             # Este archivo
```

## 🔬 Metodología

El proyecto sigue una metodología que incluye:

1. **Revisión bibliográfica**: Estado del arte de las narices electrónicas
2. **Diseño del sistema**: Arquitectura software
3. **Implementación**: Construcción del prototipo
4. **Recolección de datos**: Muestras de entrenamiento y validación
5. **Entrenamiento del modelo**: Machine Learning para clasificación
6. **Pruebas y validación**: Comparación con agentes caninos
7. **Análisis de resultados**: Evaluación de rendimiento y viabilidad

## 🤝 Colaboración

Este proyecto ha sido desarrollado en colaboración con:
- **Guardia Civil**: Unidad Canina de Detección de Sustancias
- **Universidad de Extremadura**: Grupo de investigación en sensores y sistemas inteligentes

## 📄 Licencia

Este proyecto está bajo la licencia especificada en el archivo [LICENSE](LICENSE).

## 📧 Contacto

Para más información sobre este proyecto:
- **Autor**: Raúl Martín-Romo Sánchez
- **Universidad**: Universidad de Extremadura - Escuela Politécnica de Cáceres

---

*Trabajo Fin de Grado - Grado en Ingeniería Informática del Software*  
*Universidad de Extremadura - 2026*
