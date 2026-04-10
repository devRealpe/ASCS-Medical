workspace "ASCSMedical" "Sistema de Etiquetado y Diagnóstico Asistido de Sonidos Cardíacos (Auscultación)" {

    !identifiers hierarchical

    model {
        // ══════════════════════════════════════════════════════════════════════
        // PERSONAS
        // ══════════════════════════════════════════════════════════════════════

        personalMedico = person "Personal Médico" "Cardiólogos, médicos y personal de salud que etiquetan sonidos cardíacos, registran diagnósticos y entrenan modelos de IA."

        // ══════════════════════════════════════════════════════════════════════
        // SISTEMAS EXTERNOS
        // ══════════════════════════════════════════════════════════════════════

        awsS3 = softwareSystem "AWS S3" "Servicio de almacenamiento en la nube de Amazon. Almacena archivos de audio WAV (.wav) y metadatos JSON de las auscultaciones." {
            tags "External"
        }

        awsCognito = softwareSystem "AWS Cognito" "Servicio de identidad de Amazon utilizado internamente por el SDK de Amplify para autorizar el acceso a los buckets de AWS S3. No gestiona la autenticación de usuarios del sistema." {
            tags "External"
        }

        // ══════════════════════════════════════════════════════════════════════
        // SISTEMA PRINCIPAL — ASCS-Medical
        // ══════════════════════════════════════════════════════════════════════

        ascsMedical = softwareSystem "ASCS-Medical" "Plataforma para el etiquetado, almacenamiento y diagnóstico asistido por IA de sonidos cardíacos mediante auscultación digital." {

            // ──────────────────────────────────────────────────────────────────
            // CONTENEDOR: Aplicación Móvil Flutter
            // ──────────────────────────────────────────────────────────────────

            appMovil = container "Aplicación Móvil" "Aplicación multiplataforma que permite al personal médico registrar formularios de auscultación, subir audios, consultar diagnósticos y entrenar modelos de IA." "Flutter / Dart / BLoC" {
                tags "MobileApp"

                // ─── Capa de Presentación — Páginas (Vistas) ─────────────────

                vistaAuth = component "Página de Autenticación" "Formularios de inicio de sesión y registro de usuarios. Permite acceder al sistema con credenciales." "Flutter Widget (LoginRegisterPage)" {
                    tags "Vista"
                }
                vistaHome = component "Página Principal" "Pantalla principal con navegación a los módulos del sistema: formulario, diagnósticos y entrenamiento." "Flutter Widget (HomePage)" {
                    tags "Vista"
                }
                vistaFormulario = component "Página de Formulario" "Formulario de etiquetado de sonidos cardíacos: selección de audio ZIP, datos del paciente, metadatos clínicos y foco de auscultación." "Flutter Widget (FormularioPage)" {
                    tags "Vista"
                }
                vistaDiagnosticos = component "Página de Diagnósticos" "Listado y detalle de diagnósticos realizados, agrupados por creador, con opción de confirmar valvulopatías." "Flutter Widget (DiagnosticosPage)" {
                    tags "Vista"
                }
                vistaEntrenamiento = component "Página de Entrenamiento" "Interfaz para enviar muestras de audio al modelo de IA y obtener diagnósticos automáticos." "Flutter Widget (EntrenamientoPage)" {
                    tags "Vista"
                }

                // ─── Capa de Presentación — BLoCs (Gestión de Estado) ────────

                authBloc = component "AuthBloc" "Gestiona el estado de autenticación: login, registro y cierre de sesión. Emite estados de carga, éxito y error." "flutter_bloc (BLoC)" {
                    tags "Bloc"
                }
                configBloc = component "ConfigBloc" "Gestiona la carga de configuración médica: hospitales, consultorios, focos de auscultación, categorías de anomalía y enfermedades." "flutter_bloc (BLoC)" {
                    tags "Bloc"
                }
                formularioBloc = component "FormularioBloc" "Orquesta el flujo completo de envío del formulario: extracción de audios del ZIP, subida a S3 o almacenamiento local, envío de metadatos, entrenamiento y diagnóstico IA." "flutter_bloc (BLoC)" {
                    tags "Bloc"
                }
                diagnosticoBloc = component "DiagnosticoBloc" "Gestiona la consulta de diagnósticos médicos por creador y la confirmación de valvulopatías." "flutter_bloc (BLoC)" {
                    tags "Bloc"
                }
                entrenamientoBloc = component "EntrenamientoBloc" "Gestiona el envío de muestras al servicio de diagnóstico IA y la creación de diagnósticos en el sistema." "flutter_bloc (BLoC)" {
                    tags "Bloc"
                }
                uploadBloc = component "UploadBloc" "Gestiona el estado de progreso durante la subida de archivos al servidor." "flutter_bloc (BLoC)" {
                    tags "Bloc"
                }

                // ─── Capa de Dominio — Casos de Uso ──────────────────────────

                enviarFormularioUC = component "EnviarFormularioUseCase" "Coordina el envío de un formulario completo con su archivo ZIP de 4 audios cardíacos al repositorio correspondiente." "Caso de Uso" {
                    tags "UseCase"
                }
                generarNombreUC = component "GenerarNombreArchivoUseCase" "Genera el nombre base del archivo siguiendo la nomenclatura estándar: SC_YYYYMMDD_HHCC_FF_EST." "Caso de Uso" {
                    tags "UseCase"
                }
                obtenerHospitalesUC = component "ObtenerHospitalesUseCase" "Obtiene la lista de hospitales/instituciones disponibles desde el repositorio de configuración." "Caso de Uso" {
                    tags "UseCase"
                }
                obtenerConsultoriosUC = component "ObtenerConsultoriosPorHospitalUseCase" "Obtiene los consultorios asociados a un hospital específico." "Caso de Uso" {
                    tags "UseCase"
                }
                obtenerFocosUC = component "ObtenerFocosUseCase" "Obtiene los focos de auscultación disponibles (Aórtico, Pulmonar, Tricúspide, Mitral, Erb)." "Caso de Uso" {
                    tags "UseCase"
                }

                // ─── Capa de Dominio — Interfaces de Repositorio ─────────────

                formularioRepoIntf = component "FormularioRepository" "Interfaz abstracta que define el contrato para el envío de formularios y la generación de nombres de archivo." "Domain Interface (Abstract)" {
                    tags "RepoInterface"
                }
                configRepoIntf = component "ConfigRepository" "Interfaz abstracta que define el contrato para la obtención de configuración médica y consultorios." "Domain Interface (Abstract)" {
                    tags "RepoInterface"
                }

                // ─── Capa de Datos — Implementaciones de Repositorio ─────────

                formularioRepoImpl = component "FormularioRepositoryImpl" "Implementación del repositorio de formularios. Coordina la extracción de audios del ZIP, subida a AWS S3 y generación de metadatos." "Data Layer (Repository)" {
                    tags "RepoImpl"
                }
                configRepoImpl = component "ConfigRepositoryImpl" "Implementación del repositorio de configuración. Obtiene hospitales, focos, categorías y enfermedades desde la API REST." "Data Layer (Repository)" {
                    tags "RepoImpl"
                }

                // ─── Capa de Datos — Data Sources Remotos ────────────────────

                authDS = component "AuthRemoteDataSource" "Data source remoto de autenticación. Comunica con la API REST para login y registro de usuarios mediante HTTP/JSON." "Data Source (Remote)" {
                    tags "DataSource"
                }
                configDS = component "ConfigRemoteDataSource" "Data source remoto de configuración médica. Obtiene en paralelo hospitales, focos, categorías de anomalía, enfermedades y consultorios de la API." "Data Source (Remote)" {
                    tags "DataSource"
                }
                awsS3DS = component "AwsS3RemoteDataSource" "Data source remoto de AWS S3. Sube los 4 archivos WAV a carpetas específicas (Audios, ECG, ECG_1, ECG_2) y metadatos JSON usando el SDK de Amplify." "Data Source (Remote)" {
                    tags "DataSource"
                }
                diagnosticoDS = component "DiagnosticoRemoteDataSource" "Data source remoto de diagnósticos. Consulta diagnósticos por creador, crea nuevos diagnósticos y confirma valvulopatías en la API." "Data Source (Remote)" {
                    tags "DataSource"
                }
                diagnoseDS = component "DiagnoseRemoteDataSource" "Data source remoto del servicio de diagnóstico IA. Envía audio WAV + metadatos JSON al endpoint /api/v1/diagnose mediante multipart." "Data Source (Remote)" {
                    tags "DataSource"
                }
                sampleTrainDS = component "SampleTrainRemoteDataSource" "Data source remoto de muestras de entrenamiento. Envía los 4 audios + metadatos JSON al endpoint /api/v1/train/sample." "Data Source (Remote)" {
                    tags "DataSource"
                }

                // ─── Capa de Datos — Data Sources Locales ────────────────────

                localStorageDS = component "LocalStorageDataSource" "Data source local. Extrae los 4 archivos WAV del ZIP, los clasifica por tipo (Principal, ECG, ECG_1, ECG_2) y gestiona almacenamiento temporal." "Data Source (Local)" {
                    tags "DataSourceLocal"
                }

                // ─── Core — Servicios Transversales ──────────────────────────

                sessionService = component "SessionService" "Servicio singleton que gestiona el token JWT y los datos del usuario autenticado en memoria y SharedPreferences." "Core Service (Singleton)" {
                    tags "CoreService"
                }
                networkInfo = component "NetworkInfo" "Verifica la conectividad a internet antes de realizar operaciones remotas mediante Connectivity Plus." "Core Service" {
                    tags "CoreService"
                }
                storagePreferenceService = component "StoragePreferenceService" "Gestiona la preferencia de modo de almacenamiento del usuario: Local, Nube (S3) o Entrenamiento." "Core Service" {
                    tags "CoreService"
                }
            }

            // ──────────────────────────────────────────────────────────────────
            // CONTENEDOR: Servidor API REST
            // ──────────────────────────────────────────────────────────────────

            apiBackend = container "Servidor API REST" "API REST que gestiona la autenticación de usuarios (registro y login con JWT), configuración médica (hospitales, consultorios, focos, categorías, enfermedades), diagnósticos e instituciones." "Node.js / Express" {
                tags "Backend"

                moduloAuth = component "Módulo de Autenticación" "Gestiona registro y login de usuarios con JWT. Endpoints: /api/auth/register, /api/auth/login." "Express Router"
                moduloConfig = component "Módulo de Configuración" "Administra la configuración médica: instituciones, consultorios, focos de auscultación, categorías de anomalía y enfermedades." "Express Router"
                moduloDiagnosticos = component "Módulo de Diagnósticos" "Gestiona la creación, consulta y confirmación de diagnósticos médicos." "Express Router"
            }

            // ──────────────────────────────────────────────────────────────────
            // CONTENEDOR: Servicio de Diagnóstico IA
            // ──────────────────────────────────────────────────────────────────

            servicioIA = container "Servicio de Diagnóstico IA" "Microservicio de inteligencia artificial que procesa audios cardíacos para entrenamiento del modelo y generación de diagnósticos automáticos." "Python / Flask" {
                tags "IAService"

                moduloEntrenamiento = component "Módulo de Entrenamiento" "Recibe muestras de audio con metadatos para entrenar/actualizar el modelo de clasificación de sonidos cardíacos. Endpoint: /api/v1/train/sample." "Flask Route"
                moduloDiagnosticoIA = component "Módulo de Diagnóstico IA" "Procesa un audio cardíaco con metadatos y retorna un diagnóstico automático basado en el modelo entrenado. Endpoint: /api/v1/diagnose." "Flask Route"
            }

            // ──────────────────────────────────────────────────────────────────
            // CONTENEDOR: Base de Datos
            // ──────────────────────────────────────────────────────────────────

            baseDatos = container "Base de Datos" "Almacena información estructurada: usuarios, instituciones, consultorios, focos de auscultación, categorías de anomalía, enfermedades y diagnósticos." "PostgreSQL" {
                tags "Database"
            }

            // ──────────────────────────────────────────────────────────────────
            // CONTENEDOR: Almacenamiento Local del Dispositivo
            // ──────────────────────────────────────────────────────────────────

            almacenamientoLocal = container "Almacenamiento Local" "Sistema de archivos del dispositivo móvil. Almacena temporalmente archivos ZIP extraídos, audios WAV y preferencias del usuario (SharedPreferences)." "File System / SharedPreferences" {
                tags "LocalStorage"
            }
        }

        // ══════════════════════════════════════════════════════════════════════
        // RELACIONES — NIVEL 1: CONTEXTO DEL SISTEMA
        // ══════════════════════════════════════════════════════════════════════

        personalMedico -> ascsMedical "Registra formularios de auscultación, consulta diagnósticos y entrena modelos de IA"
        ascsMedical -> awsS3 "Almacena archivos de audio WAV y metadatos JSON de auscultaciones"
        ascsMedical -> awsCognito "Autoriza el acceso a los buckets de S3 de forma transparente mediante Amplify SDK"

        // ══════════════════════════════════════════════════════════════════════
        // RELACIONES — NIVEL 2: CONTENEDORES
        // ══════════════════════════════════════════════════════════════════════

        personalMedico -> ascsMedical.appMovil "Interactúa con el sistema desde un dispositivo móvil (Android/iOS)"
        ascsMedical.appMovil -> ascsMedical.apiBackend "Autentica usuarios (login/registro) y gestiona configuración médica y diagnósticos" "REST API / HTTP / JSON"
        ascsMedical.appMovil -> ascsMedical.servicioIA "Envía audios cardíacos para entrenamiento del modelo y diagnóstico automático" "REST API / HTTP / Multipart"
        ascsMedical.appMovil -> awsS3 "Sube archivos de audio WAV y metadatos JSON a buckets S3" "AWS Amplify SDK"
        ascsMedical.appMovil -> awsCognito "Autoriza de forma transparente el acceso a los buckets S3" "AWS Amplify SDK"
        ascsMedical.appMovil -> ascsMedical.almacenamientoLocal "Lee y escribe archivos temporales y preferencias del usuario"
        ascsMedical.apiBackend -> ascsMedical.baseDatos "Realiza operaciones CRUD (consultar, insertar, actualizar, eliminar)"
        ascsMedical.servicioIA -> ascsMedical.baseDatos "Lee datos de entrenamiento y almacena resultados de modelos"

        // ══════════════════════════════════════════════════════════════════════
        // RELACIONES — NIVEL 3: COMPONENTES DE LA APLICACIÓN MÓVIL
        // ══════════════════════════════════════════════════════════════════════

        // ─── Persona → Páginas (Vistas) ──────────────────────────────────────

        personalMedico -> ascsMedical.appMovil.vistaAuth "Inicia sesión o registra una nueva cuenta"
        personalMedico -> ascsMedical.appMovil.vistaHome "Navega entre los módulos del sistema"
        personalMedico -> ascsMedical.appMovil.vistaFormulario "Registra formularios de auscultación con archivos de audio"
        personalMedico -> ascsMedical.appMovil.vistaDiagnosticos "Consulta diagnósticos realizados y confirma valvulopatías"
        personalMedico -> ascsMedical.appMovil.vistaEntrenamiento "Envía muestras al modelo de IA y obtiene diagnósticos automáticos"

        // ─── Páginas → BLoCs ─────────────────────────────────────────────────

        ascsMedical.appMovil.vistaAuth -> ascsMedical.appMovil.authBloc "Dispara eventos de login y registro"
        ascsMedical.appMovil.vistaHome -> ascsMedical.appMovil.configBloc "Solicita carga de configuración médica inicial"
        ascsMedical.appMovil.vistaFormulario -> ascsMedical.appMovil.formularioBloc "Dispara el envío del formulario completo"
        ascsMedical.appMovil.vistaFormulario -> ascsMedical.appMovil.configBloc "Solicita hospitales, consultorios y focos"
        ascsMedical.appMovil.vistaFormulario -> ascsMedical.appMovil.uploadBloc "Consulta el estado de progreso de subida"
        ascsMedical.appMovil.vistaDiagnosticos -> ascsMedical.appMovil.diagnosticoBloc "Solicita carga y confirmación de diagnósticos"
        ascsMedical.appMovil.vistaEntrenamiento -> ascsMedical.appMovil.entrenamientoBloc "Dispara envío de muestra y diagnóstico IA"
        ascsMedical.appMovil.vistaEntrenamiento -> ascsMedical.appMovil.configBloc "Solicita configuración médica para el formulario"

        // ─── BLoCs → Casos de Uso ────────────────────────────────────────────

        ascsMedical.appMovil.configBloc -> ascsMedical.appMovil.configRepoIntf "Obtiene configuración médica completa"
        ascsMedical.appMovil.configBloc -> ascsMedical.appMovil.obtenerConsultoriosUC "Obtiene consultorios por hospital"
        ascsMedical.appMovil.formularioBloc -> ascsMedical.appMovil.enviarFormularioUC "Ejecuta el envío del formulario"
        ascsMedical.appMovil.formularioBloc -> ascsMedical.appMovil.generarNombreUC "Genera el nombre base del archivo de audio"
        ascsMedical.appMovil.formularioBloc -> ascsMedical.appMovil.networkInfo "Verifica conectividad antes de operaciones remotas"
        ascsMedical.appMovil.formularioBloc -> ascsMedical.appMovil.storagePreferenceService "Consulta el modo de almacenamiento seleccionado"

        // ─── BLoCs → Data Sources (acceso directo) ───────────────────────────

        ascsMedical.appMovil.authBloc -> ascsMedical.appMovil.authDS "Ejecuta login y registro de usuarios"
        ascsMedical.appMovil.diagnosticoBloc -> ascsMedical.appMovil.diagnosticoDS "Consulta y confirma diagnósticos"
        ascsMedical.appMovil.entrenamientoBloc -> ascsMedical.appMovil.diagnoseDS "Envía audio para diagnóstico IA"
        ascsMedical.appMovil.entrenamientoBloc -> ascsMedical.appMovil.diagnosticoDS "Crea diagnósticos en el sistema"
        ascsMedical.appMovil.formularioBloc -> ascsMedical.appMovil.localStorageDS "Extrae audios WAV del archivo ZIP"
        ascsMedical.appMovil.formularioBloc -> ascsMedical.appMovil.sampleTrainDS "Envía muestras de entrenamiento al servicio IA"
        ascsMedical.appMovil.formularioBloc -> ascsMedical.appMovil.diagnoseDS "Solicita diagnóstico automático por IA"
        ascsMedical.appMovil.formularioBloc -> ascsMedical.appMovil.diagnosticoDS "Crea diagnósticos en el sistema"

        // ─── Casos de Uso → Repositorios (Interfaces) ────────────────────────

        ascsMedical.appMovil.enviarFormularioUC -> ascsMedical.appMovil.formularioRepoIntf "Delega el envío del formulario"
        ascsMedical.appMovil.generarNombreUC -> ascsMedical.appMovil.formularioRepoIntf "Delega la generación del nombre"
        ascsMedical.appMovil.obtenerHospitalesUC -> ascsMedical.appMovil.configRepoIntf "Delega la obtención de hospitales"
        ascsMedical.appMovil.obtenerConsultoriosUC -> ascsMedical.appMovil.configRepoIntf "Delega la obtención de consultorios"
        ascsMedical.appMovil.obtenerFocosUC -> ascsMedical.appMovil.configRepoIntf "Delega la obtención de focos"

        // ─── Interfaces → Implementaciones (Inyección de Dependencias) ───────

        ascsMedical.appMovil.formularioRepoIntf -> ascsMedical.appMovil.formularioRepoImpl "Implementado por (GetIt DI)" {
            tags "Implementacion"
        }
        ascsMedical.appMovil.configRepoIntf -> ascsMedical.appMovil.configRepoImpl "Implementado por (GetIt DI)" {
            tags "Implementacion"
        }

        // ─── Implementaciones de Repositorio → Data Sources ──────────────────

        ascsMedical.appMovil.formularioRepoImpl -> ascsMedical.appMovil.awsS3DS "Sube audios y metadatos a S3"
        ascsMedical.appMovil.formularioRepoImpl -> ascsMedical.appMovil.localStorageDS "Extrae y almacena archivos localmente"
        ascsMedical.appMovil.configRepoImpl -> ascsMedical.appMovil.configDS "Obtiene configuración de la API REST"

        // ─── Data Sources Remotos → Sistemas Externos / Contenedores ─────────

        ascsMedical.appMovil.authDS -> ascsMedical.apiBackend "Envía credenciales para login/registro" "HTTP POST / JSON"
        ascsMedical.appMovil.configDS -> ascsMedical.apiBackend "Consulta hospitales, focos, categorías y enfermedades" "HTTP GET / JSON"
        ascsMedical.appMovil.diagnosticoDS -> ascsMedical.apiBackend "Consulta, crea y confirma diagnósticos" "HTTP GET/POST/PATCH / JSON"
        ascsMedical.appMovil.awsS3DS -> awsS3 "Sube archivos WAV y metadatos JSON" "AWS Amplify SDK"
        ascsMedical.appMovil.awsS3DS -> awsCognito "Autoriza acceso al bucket S3 de forma transparente" "AWS Amplify SDK"
        ascsMedical.appMovil.sampleTrainDS -> ascsMedical.servicioIA "Envía 4 audios + metadatos para entrenamiento" "HTTP POST / Multipart"
        ascsMedical.appMovil.diagnoseDS -> ascsMedical.servicioIA "Envía audio + metadatos para diagnóstico IA" "HTTP POST / Multipart"

        // ─── Data Source Local → Almacenamiento Local ────────────────────────

        ascsMedical.appMovil.localStorageDS -> ascsMedical.almacenamientoLocal "Lee/escribe archivos temporales y preferencias"
        ascsMedical.appMovil.sessionService -> ascsMedical.almacenamientoLocal "Persiste token JWT y datos del usuario" "SharedPreferences"
        ascsMedical.appMovil.storagePreferenceService -> ascsMedical.almacenamientoLocal "Lee/escribe preferencia de modo de almacenamiento" "SharedPreferences"

        // ══════════════════════════════════════════════════════════════════════
        // RELACIONES — NIVEL 3: COMPONENTES DEL SERVIDOR API REST
        // ══════════════════════════════════════════════════════════════════════

        ascsMedical.appMovil.authDS -> ascsMedical.apiBackend.moduloAuth "Envía credenciales de login/registro" "HTTP POST / JSON"
        ascsMedical.appMovil.configDS -> ascsMedical.apiBackend.moduloConfig "Consulta configuración médica" "HTTP GET / JSON"
        ascsMedical.appMovil.diagnosticoDS -> ascsMedical.apiBackend.moduloDiagnosticos "Consulta, crea y confirma diagnósticos" "HTTP / JSON"

        ascsMedical.apiBackend.moduloAuth -> ascsMedical.baseDatos "Lee y escribe usuarios y credenciales"
        ascsMedical.apiBackend.moduloConfig -> ascsMedical.baseDatos "Lee instituciones, consultorios, focos, categorías y enfermedades"
        ascsMedical.apiBackend.moduloDiagnosticos -> ascsMedical.baseDatos "Lee y escribe diagnósticos médicos"

        // ══════════════════════════════════════════════════════════════════════
        // RELACIONES — NIVEL 3: COMPONENTES DEL SERVICIO IA
        // ══════════════════════════════════════════════════════════════════════

        ascsMedical.appMovil.sampleTrainDS -> ascsMedical.servicioIA.moduloEntrenamiento "Envía muestras de entrenamiento" "HTTP POST / Multipart"
        ascsMedical.appMovil.diagnoseDS -> ascsMedical.servicioIA.moduloDiagnosticoIA "Solicita diagnóstico automático" "HTTP POST / Multipart"
    }

    // ══════════════════════════════════════════════════════════════════════════
    // VISTAS
    // ══════════════════════════════════════════════════════════════════════════

    views {

        // ─── Nivel 1: Diagrama de Contexto del Sistema ───────────────────────

        systemContext ascsMedical "01_Contexto_Sistema" {
            include *
            autolayout tb
            title "ASCS-Medical — Diagrama de Contexto del Sistema"
            description "Vista de alto nivel que muestra el sistema ASCS-Medical, los usuarios y los sistemas externos con los que interactúa."
        }

        // ─── Nivel 2: Diagrama de Contenedores ──────────────────────────────

        container ascsMedical "02_Contenedores" {
            include *
            autolayout tb
            title "ASCS-Medical — Diagrama de Contenedores"
            description "Muestra los contenedores que componen el sistema: la aplicación móvil, el servidor API REST, el servicio de IA, la base de datos y el almacenamiento local."
        }

        // ─── Nivel 3: Componentes de la Aplicación Móvil Flutter ─────────────

        component ascsMedical.appMovil "03_Componentes_App_Movil" {
            include *
            autolayout tb
            title "ASCS-Medical — Componentes de la Aplicación Móvil (Clean Architecture)"
            description "Arquitectura interna de la aplicación Flutter siguiendo Clean Architecture con patrón BLoC: Capa de Presentación (Páginas + BLoCs), Capa de Dominio (Casos de Uso + Repositorios), Capa de Datos (Data Sources)."
        }

        // ─── Nivel 3: Componentes del Servidor API REST ──────────────────────

        component ascsMedical.apiBackend "04_Componentes_API_Backend" {
            include *
            autolayout tb
            title "ASCS-Medical — Componentes del Servidor API REST"
            description "Módulos funcionales del servidor API REST: Autenticación, Configuración Médica y Diagnósticos."
        }

        // ─── Nivel 3: Componentes del Servicio de Diagnóstico IA ─────────────

        component ascsMedical.servicioIA "05_Componentes_Servicio_IA" {
            include *
            autolayout tb
            title "ASCS-Medical — Componentes del Servicio de Diagnóstico IA"
            description "Módulos funcionales del microservicio de IA: Entrenamiento de modelos y Diagnóstico automático de sonidos cardíacos."
        }

        // ══════════════════════════════════════════════════════════════════════
        // ESTILOS
        // ══════════════════════════════════════════════════════════════════════

        styles {
            element "Person" {
                shape Person
                background #08427B
                color #ffffff
                stroke #052e56
                strokeWidth 4
            }

            element "Software System" {
                shape RoundedBox
                background #1168BD
                color #ffffff
                stroke #0d50a0
                strokeWidth 4
            }

            element "External" {
                shape RoundedBox
                background #999999
                color #ffffff
                stroke #6b6b6b
                strokeWidth 4
            }

            element "Container" {
                shape RoundedBox
                background #438dd5
                color #ffffff
                stroke #1168BD
                strokeWidth 4
            }

            element "MobileApp" {
                shape MobileDevicePortrait
                background #438dd5
                color #ffffff
                stroke #1168BD
                strokeWidth 4
            }

            element "Backend" {
                shape Hexagon
                background #438dd5
                color #ffffff
                stroke #1168BD
                strokeWidth 4
            }

            element "IAService" {
                shape Hexagon
                background #6a0dad
                color #ffffff
                stroke #4a0080
                strokeWidth 4
            }

            element "Database" {
                shape Cylinder
                background #1168BD
                color #ffffff
                stroke #0d50a0
                strokeWidth 4
            }

            element "LocalStorage" {
                shape Folder
                background #6b8e23
                color #ffffff
                stroke #4a6a10
                strokeWidth 4
            }

            element "Component" {
                shape Component
                background #85bbf0
                color #000000
                stroke #1168BD
                strokeWidth 3
            }

            element "Vista" {
                shape WebBrowser
                background #438dd5
                color #ffffff
                stroke #1168BD
                strokeWidth 4
            }

            element "Bloc" {
                shape RoundedBox
                background #2d89ef
                color #ffffff
                stroke #1168BD
                strokeWidth 4
            }

            element "UseCase" {
                shape Circle
                background #ffc107
                color #000000
                stroke #cc9a06
                strokeWidth 3
            }

            element "RepoInterface" {
                shape Diamond
                background #e74c3c
                color #ffffff
                stroke #c0392b
                strokeWidth 3
            }

            element "RepoImpl" {
                shape RoundedBox
                background #e67e22
                color #ffffff
                stroke #d35400
                strokeWidth 3
            }

            element "DataSource" {
                shape Pipe
                background #27ae60
                color #ffffff
                stroke #1e8449
                strokeWidth 3
            }

            element "DataSourceLocal" {
                shape Pipe
                background #6b8e23
                color #ffffff
                stroke #4a6a10
                strokeWidth 3
            }

            element "CoreService" {
                shape Ellipse
                background #8e44ad
                color #ffffff
                stroke #6c3483
                strokeWidth 3
            }

            relationship "Relationship" {
                color #707070
                thickness 2
            }

            relationship "Implementacion" {
                style Dashed
                color #999999
                thickness 2
            }
        }
    }
}
