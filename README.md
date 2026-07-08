# 🌱 AgroMoz — Marketplace Agrícola de Moçambique (v2)

Aplicação móvel Flutter que liga **agricultores, compradores, empresas agrícolas e fornecedores** em todo Moçambique — totalmente integrada com o site agromoz.com (mesma base de dados, mesmos utilizadores, mesmos produtos).

> Consome a API PHP em `appapi/` (incluída no pacote `agromoz-api`). `baseUrl` já aponta para `https://agromoz.com/appapi/v1`.

---

## ✨ O que há de novo na v3 (Julho 2026)

- **Aba Fornecedores** no menu: directório de empresas com pesquisa e filtro por tipo (Agricultores, Horticultores, Avicultores, Cunicultores, Fornecedores de Insumos), com nota, nº de produtos e acesso ao perfil.
- **Home como long page de venda**: pesquisa → banners → categorias (só as que têm produtos) → produtos em destaque → "Notícias e dicas" (artigos abrem na app) → últimos anúncios → recomendados → CTA "Cria a tua página de negócio".
- **Artigo único redesenhado**: capa com gradiente e título sobreposto, chip de categoria, data + tempo de leitura, tipografia editorial (h2 em verde, citações com barra lateral) e botão de partilha.
- **Editar Página de Negócio**: novo ecrã para mudar logo, capa, descrição, contactos, categorias e localização (botão "Editar Página" no dashboard).
- **Wizard corrigido**: se a API não responder, os 5 tipos de perfil aparecem na mesma (fallback local) — nunca ficas preso no passo 1.
- API: nova rota `GET /farmers` (lista pública de empresas com `?type`, `?q`, `?province`).

## ✨ O que havia de novo na v2

- **Registo igual ao site**: nome, e-mail, telefone, província, senha + confirmação, checkbox "🌱 Quero criar uma página de negócio" e aceitação de Termos. A conta fica por confirmar até introduzir o **código de 6 dígitos enviado por e-mail** (mesmo mecanismo do site).
- **Fluxo profissional completo dentro da app**:
  - Wizard de 5 passos para criar a Página de Negócio (perfil → dados → categorias por tipo → localização por GPS → logo/capa/galeria). A página entra **em revisão** ("pendente") até ser aprovada no painel admin do site.
  - Dashboard com os mesmos cartões do site: produtos, disponíveis, a esgotar, visitas.
  - Gestão de produtos: criar/editar com foto, preço opcional ("sob consulta"), unidade, mudança rápida de disponibilidade (✅/⚠️/❌), destaque e eliminar.
- **Aprender**: os artigos educativos do site abrem **dentro da app** (lista com filtro por categoria + leitura completa em HTML). O utilizador nunca sai da app.
- **Contacto por WhatsApp**: as abas de Pesquisa e Mensagens foram removidas. "Contactar" abre o **WhatsApp** do vendedor/empresa (com fallback wa.me), além do botão Ligar. Pesquisa vive agora dentro do Marketplace.
- **Avaliações funcionais**: qualquer utilizador pode avaliar uma página (1–5 ⭐ + comentário); o dono recebe notificação na app. Uma avaliação por utilizador (reenviar actualiza).
- **Navegação nova**: Início · Marketplace · Aprender · Perfil. Entrada "Meu Negócio" no Perfil.

## 🚀 Como correr

```bash
flutter pub get
flutter run
```

### Permissões Android (android/app/src/main/AndroidManifest.xml)
Se geraste a pasta `android/` com `flutter create .`, adiciona dentro de `<manifest>`:

```xml
<uses-permission android:name="android.permission.INTERNET"/>
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION"/>
<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION"/>
<!-- Para abrir o WhatsApp a partir da app (Android 11+) -->
<queries>
  <package android:name="com.whatsapp"/>
  <intent><action android:name="android.intent.action.VIEW"/>
    <data android:scheme="https"/></intent>
  <intent><action android:name="android.intent.action.DIAL"/></intent>
</queries>
```

### iOS (ios/Runner/Info.plist)
```xml
<key>NSLocationWhenInUseUsageDescription</key>
<string>Usamos a localização para marcar o local do teu negócio.</string>
<key>NSPhotoLibraryUsageDescription</key>
<string>Precisamos das tuas fotos para o logo e os produtos.</string>
<key>LSApplicationQueriesSchemes</key>
<array><string>whatsapp</string><string>tel</string></array>
```

## 🔌 API

Base: `https://agromoz.com/appapi/v1` (ficheiro único a mudar: `lib/core/constants/api_endpoints.dart`).

Rotas novas usadas pela v2:
`POST /register` (com `wants_business`) · `POST /verify-email` · `POST /resend-code` ·
`GET /articles`, `/articles/{slug}`, `/articles/categories` ·
`GET|POST /business`, `POST /business/update`, `GET /business/stats`, `GET /business/types` ·
`GET|POST /business/products`, `POST /business/products/{id}`, `PATCH .../availability` ·
`POST /farmers/{id}/reviews`.

## 🏗️ Arquitectura

Clean Architecture + MVVM (Provider). `lib/core` (Dio, tema M3, storage, utils) → `lib/data` (models + repositories) → `lib/providers` → `lib/presentation`.

## 📌 Notas

- `DEBUG_OTP=true` na API devolve o código na resposta (a app pré-preenche o campo para facilitar testes). **Desligar em produção.**
- FCM: o registo de device token e o centro de notificações continuam prontos para ligar o Firebase Cloud Messaging.
