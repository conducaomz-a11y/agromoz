# AgroMoz — Setup dos novos módulos (v4)

Esta versão adiciona três módulos: **image_picker completo**, **notificações locais + FCM**, e **modo offline (Hive)**. O código Dart está todo pronto. Faltam apenas passos nativos que só podem ser feitos depois de gerar a pasta `android/`.

## 1. Instalar dependências

```bash
cd agromoz
flutter pub get
```

Se ainda não tens a pasta `android/` (o zip não a inclui), gera-a primeiro:

```bash
flutter create . --org mz.agromoz --platforms android
```

Isto não toca no teu código em `lib/` — só cria o esqueleto nativo.

## 2. Firebase / FCM (notificações push)

O push real precisa de um projeto Firebase teu. Sem este passo a app **compila e corre à mesma** — só o push fica inativo (as notificações locais funcionam na mesma).

1. Cria um projeto em https://console.firebase.google.com
2. Adiciona uma app Android com o package `mz.agromoz.agromoz`
3. Descarrega o `google-services.json` e coloca-o em: `android/app/google-services.json`
4. Em `android/settings.gradle` (ou `android/build.gradle`), adiciona o plugin:

   ```gradle
   plugins {
       id "com.google.gms.google-services" version "4.4.2" apply false
   }
   ```

5. Em `android/app/build.gradle`, no topo dos plugins:

   ```gradle
   plugins {
       id "com.android.application"
       id "kotlin-android"
       id "dev.flutter.flutter-gradle-plugin"
       id "com.google.gms.google-services"   // <-- adicionar
   }
   ```

6. `minSdkVersion` deve ser **pelo menos 21** (o firebase_messaging exige). Em `android/app/build.gradle`:

   ```gradle
   defaultConfig {
       minSdkVersion 21
   }
   ```

## 3. Permissões Android

Em `android/app/src/main/AndroidManifest.xml`, dentro de `<manifest>` (antes de `<application>`):

```xml
<uses-permission android:name="android.permission.INTERNET"/>
<uses-permission android:name="android.permission.CAMERA"/>
<uses-permission android:name="android.permission.POST_NOTIFICATIONS"/>
```

A câmara é para o image_picker; POST_NOTIFICATIONS é obrigatória no Android 13+.

## 4. Backend — endpoints esperados

Os módulos assumem estes endpoints (ajusta o backend PHP conforme):

| Método | Caminho | Uso |
|--------|---------|-----|
| POST | `/profile/avatar` | Upload do avatar (campo multipart `avatar`) → devolve user atualizado |
| POST | `/devices` | Regista o token FCM (`{token, platform}`) |
| GET  | `/notifications` | Lista de notificações (já existia) |

O upload de avatar e de imagem de produto usam `multipart/form-data`, tal como o resto da app já fazia.

## 5. Compilar

```bash
flutter build apk --debug
# ou release quando estiver pronto:
flutter build apk --release
```

## O que cada módulo faz

**image_picker** — `ImagePickerService` centraliza escolha câmara/galeria + compressão (dimensão e qualidade), importante para dados caros. Ligado ao avatar (Editar perfil) e ao formulário de produtos.

**Notificações** — `LocalNotificationService` mostra alertas do sistema; `PushNotificationService` regista o token FCM e reencaminha pushes de foreground. O `NotificationProvider` dispara um alerta local sempre que deteta novos itens não lidos.

**Offline (Hive)** — `CacheService` guarda respostas de leitura. Os repositórios de produtos e artigos usam *cache-then-network*: mostram o último cache quando a rede falha. O `OfflineBanner` avisa o utilizador. O cache é limpo no logout.
