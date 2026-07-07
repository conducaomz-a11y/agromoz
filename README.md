# 🌱 AgroMoz — Marketplace Agrícola de Moçambique

Aplicação móvel Flutter (Android e iOS) que liga **agricultores, compradores, empresas agrícolas, fornecedores e prestadores de serviços** em todo Moçambique.

> Apenas app móvel — consome uma REST API existente. Sem backend nem base de dados incluídos.

---

## ✨ Funcionalidades

- **Autenticação completa**: Splash animado, Onboarding (3 slides), Login, Registo (com papel e província), Recuperar palavra-passe, verificação **OTP de 6 dígitos**, sessão persistente com refresh automático de token.
- **Home**: barra de pesquisa, carrossel de banners (autoplay), categorias, produtos em destaque, últimos anúncios, recomendados.
- **Marketplace**: grelha ⇄ lista, **scroll infinito**, pull-to-refresh, filtros por província, distrito, categoria, faixa de preço e estado do produto.
- **Detalhes do produto**: galeria com indicadores, preço em MT, chips de estado/localização, cartão do vendedor, **ligar / enviar mensagem / partilhar / favoritos** (update optimista), produtos relacionados.
- **Perfil do agricultor**: foto, bio, avaliações com estrelas, tabs Produtos/Avaliações, botão de contacto.
- **Chat profissional**: bolhas de texto e imagem, estado online, indicador "a escrever…", envio optimista com estado (relógio → ✓ → ✓✓).
- **Notificações**: centro de notificações **pronto para FCM** (endpoint de registo de device token incluído).
- **Pesquisa global**: sugestões live com debounce (350 ms); resultados de produtos, agricultores, empresas e categorias.
- **Perfil do utilizador**: editar perfil, mudar palavra-passe, favoritos (swipe para remover), meus anúncios, definições com **tema claro/escuro/sistema**, logout.

## 🏗️ Arquitectura

Clean Architecture + **MVVM** com **Provider**:

```
lib/
├── core/            # constantes, tema M3, cliente Dio, storage seguro, utils
├── data/
│   ├── models/      # parsing JSON defensivo
│   └── repositories/# uma classe por domínio da API
├── providers/       # ViewModels (ChangeNotifier) + máquina de estados ViewStatus
├── presentation/
│   ├── screens/     # um directório por ecrã
│   └── widgets/     # componentes reutilizáveis (cards, shimmer, estados vazios…)
└── routes/          # rotas nomeadas centralizadas
```

- **Estado de UI unificado**: `ViewStatus { initial, loading, loadingMore, success, empty, error }` em todos os providers.
- **Rede**: singleton `ApiClient` (Dio) com Bearer token automático, **refresh transparente em 401** (uma retry) e erros normalizados em `ApiException` com mensagens em português.
- **Tokens**: `flutter_secure_storage`; preferências (tema, onboarding): `shared_preferences`.

## 🚀 Como executar

```bash
flutter pub get
flutter run
```

Requisitos: Flutter 3.22+ / Dart 3.3+.

## 🔌 Ligar à sua API

Tudo está centralizado em **`lib/core/constants/api_endpoints.dart`**:

```dart
static const String baseUrl = 'https://api.agromoz.co.mz/v1'; // ← substitua aqui
```

Endpoints placeholder consumidos (fáceis de ajustar no mesmo ficheiro):

| Método | Endpoint | Uso |
|---|---|---|
| POST | `/login`, `/register`, `/forgot-password`, `/verify-otp`, `/refresh-token` | Autenticação |
| GET | `/products`, `/products/{id}`, `/products/featured`, `/products/recommended`, `/products/{id}/related` | Catálogo |
| GET | `/categories`, `/banners` | Home |
| GET/PUT | `/profile` · POST `/profile/password` | Conta |
| GET/POST/DELETE | `/favorites`, `/favorites/{id}` | Favoritos |
| GET | `/farmers/{id}`, `/farmers/{id}/reviews` | Perfil público |
| GET/POST | `/messages`, `/messages/{id}` | Chat |
| GET | `/notifications` · POST `/devices` | Notificações + FCM |
| GET | `/search`, `/search/suggestions` | Pesquisa global |

Formato paginado esperado: `{ "data": [...], "meta": { "current_page": 1, "last_page": 5 } }` — ajustável em `paginated_response.dart`.

## 🔔 Activar FCM (quando quiser)

1. `flutter pub add firebase_core firebase_messaging` + configuração Firebase.
2. Obtenha o token FCM e chame `NotificationRepository.registerDeviceToken(token)` (endpoint já pronto).
3. No handler de push, chame `NotificationProvider.load(refresh: true)`.

## 🎨 Design

Material 3, modo claro/escuro, verde machamba `#1B7A3D` + laranja caju `#E8730C`, cartões arredondados (16 px), shimmer loading, animações (Hero na galeria, splash animado, carrossel autoplay), estados vazios e de erro com retry em todos os ecrãs.

## 📌 Ganchos deixados prontos (TODOs intencionais)

- **Envio de imagem no chat**: adicionar `image_picker` e ligar ao `MessageRepository.sendImage` (já implementado com multipart).
- **Upload de avatar**: botão de câmara em Editar Perfil pronto para o mesmo padrão.
- **"A escrever…"**: a UI existe; ligue o sinal real (WebSocket/FCM data message) a `_showTyping` no `chat_screen.dart`.
