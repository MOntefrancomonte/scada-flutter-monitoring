# scada-flutter-monitoring
un simple scada para monitoreo

# Sistema SCADA para el Monitoreo de Consumo de Recursos en Entornos Industriales
<img width="263" height="150" alt="UCSG" src="https://github.com/user-attachments/assets/6ec356cd-eeff-4c30-af1e-36422d36f186" />

## Resumen del Proyecto
Este proyecto forma parte de la tesis de grado titulada **"Diseño de un sistema de monitoreo inteligente para el fortalecimiento de la toma de decisiones operativas en Kubiec"**. La solución integra hardware industrial de Siemens con tecnologías de nube de última generación para ofrecer una visualización en tiempo real y análisis histórico de variables críticas.

El sistema permite la transición de una infraestructura de control local a una arquitectura **IIoT (Industrial Internet of Things)**, optimizando la toma de decisiones mediante datos precisos de consumo.

---

## Arquitectura del Sistema
El proyecto se divide en cuatro capas principales:

1. **Capa de Adquisición (Hardware):**
   - **PLC Siemens S7-1200:** Encargado del control lógico y recolección de señales de campo.
   - **Transformadores de Corriente:** Medición de consumo eléctrico.
   - **Sensores de Flujo:** Monitoreo de recursos hídricos/gas.

2. **Capa de Enlace (Edge Computing):**
   - **Siemens IOT2050 Basic:** Gateway industrial que procesa los datos localmente.
   - **Node-RED:** Orquestación de flujos de datos y comunicación mediante protocolo MQTT.

3. **Capa de Nube (Backend):**
   - **AWS IoT Core:** Broker para la recepción segura de mensajes.
   - **AWS Amplify:** Gestión de autenticación y despliegue del backend.
   - **AppSync / DynamoDB:** Almacenamiento y consultas en tiempo real (GraphQL).

4. **Capa de Aplicación (Frontend):**
   - **Flutter App:** Aplicación móvil multiplataforma para la visualización de dashboards, gestión de alertas e histórico de consumo.

---

## Características Principales
* **Monitoreo en Tiempo Real:** Visualización de variables con latencia mínima.
* **Histórico de Consumo:** Gráficos detallados por rangos de fecha.
* **Gestión de Alertas:** Notificaciones push ante excedentes de consumo o fallas en el sistema.
* **Escalabilidad:** Arquitectura basada en microservicios listos para añadir más nodos de control.

---

## Requisitos Previos
Para replicar o desarrollar sobre este entorno se requiere:
* [Flutter SDK](https://docs.flutter.dev/get-started/install) (v3.x o superior)
* [Node-RED](https://nodered.org/docs/getting-started/) configurado en el IOT2050.
* Cuenta de [AWS](https://aws.amazon.com/) con CLI configurado.
* TIA Portal V16+ para la configuración del PLC.

---

## 🔧 Configuración Rápida

1. **Clonar el repositorio:**
   ```bash
   git clone [https://github.com/tu-usuario/ProyectoScada.git](https://github.com/tu-usuario/ProyectoScada.git)
   cd ProyectoScada
