# VIAJOU!

Jogo de festa para jogar com a família e os amigos, cada um no próprio celular.
Aparece uma pergunta cuja resposta é um número. Cada um chuta mais alto que o anterior, até alguém
gritar **VIAJOU!** porque acha que o último chute passou da conta. Revela a resposta: quem errou leva a carta.
No fim, quem tiver mais cartas é o **Grande Viajante**.

Feito em **Flutter**: uma base de código só, que roda na **web** (abre por link no iPhone e no Android),
como **app Android** e no **iOS**.

## O que tem

- **Salas online** com código de 4 letras e link de convite. Cada um joga no seu celular, tudo em tempo real (Firebase).
- **Modo celular único**: passa o celular de mão em mão. Funciona até sem internet e sem Firebase.
- **257 perguntas** em 9 categorias: Brasil, Corpo Humano, Bichos, Comida, Espaço, Esporte, Mundo & História, Pop & Tech e Dia a Dia. Cada uma vem com uma curiosidade.
- **Perguntas da Família**: cada jogador cria perguntas sobre a própria família ("Quantos anos a vó tinha quando casou?").
- **Visual de adesivo**: céu animado, capivara astronauta, cartas que caem e giram em 3D, teclado numérico próprio (não abre o teclado do celular), carimbo de VIAJOU MESMO!, contador girando até a resposta e confete no fim.
- **Sons** sintetizados (sem arquivos de terceiros) e vibração no celular.
- **Responsivo**: pensado para celular em pé; no computador vira um layout em duas colunas.
- Ao recarregar a página, o jogo oferece voltar para a última sala.

## Requisitos

- [Flutter](https://docs.flutter.dev/get-started/install) **3.27 ou mais novo** (`flutter --version`).
- Para o modo online: uma conta Google para criar um projeto no Firebase (o plano gratuito sobra para jogar em família).

## 1. Rodar pela primeira vez (sem Firebase)

```bash
cd viajou
flutter create . --project-name viajou --platforms=web,android,ios   # gera as pastas de plataforma
flutter pub get
flutter run -d chrome
```

O `flutter create .` só cria o que falta (pastas `android/`, `ios/` etc.). Ele não mexe no código do jogo.

Nesse momento já dá para jogar no **modo celular único**. O botão de criar sala avisa que o online ainda não foi configurado.

## 2. Ligar o modo online (Firebase)

1. Entre em <https://console.firebase.google.com> e clique em **Adicionar projeto**. O Google Analytics pode ficar desligado.
2. No menu, abra **Firestore Database** → **Criar banco de dados** → modo **produção** → região `southamerica-east1 (São Paulo)`.
3. Na aba **Regras** do Firestore, apague o que tiver, cole o conteúdo do arquivo [`firestore.rules`](firestore.rules) e clique em **Publicar**.
4. Instale as ferramentas (uma vez só):
   ```bash
   npm install -g firebase-tools
   firebase login
   dart pub global activate flutterfire_cli
   ```
5. Dentro da pasta do projeto:
   ```bash
   flutterfire configure --platforms=web,android
   ```
   Escolha o projeto que você criou. Isso substitui o arquivo `lib/firebase_options.dart` pelo verdadeiro.
6. Rode de novo com `flutter run -d chrome` e clique em **Criar sala**. Abra outra aba ou o celular e entre com o código.

> As chaves em `firebase_options.dart` não são segredo: elas só identificam o projeto. Quem protege os dados são as regras do Firestore.

## 3. Publicar na internet (para a família abrir pelo link)

### Opção A: Firebase Hosting (mais simples, já que você usa Firebase)

```bash
firebase init hosting     # pasta pública: build/web | app de página única: Sim | GitHub: Não
flutter build web --release
firebase deploy --only hosting
```

O link fica parecido com `https://seu-projeto.web.app`. É só mandar no grupo.

### Opção B: GitHub Pages (automático a cada push)

O projeto já vem com o workflow [`.github/workflows/deploy-web.yml`](.github/workflows/deploy-web.yml).

1. Rode o `flutterfire configure` (passo 2) e faça commit do `lib/firebase_options.dart`.
2. Faça push para a branch `main`. O GitHub Actions compila e publica na branch `gh-pages`.
3. No repositório, vá em **Settings → Pages**, escolha **Deploy from a branch**, branch `gh-pages`, pasta `/ (root)`.
4. O link fica `https://SEU-USUARIO.github.io/NOME-DO-REPO/`.

Para fazer o build manualmente:
`flutter build web --release --base-href /NOME-DO-REPO/`.

### Dica para o celular

No iPhone (Safari) e no Android (Chrome), use **Compartilhar → Adicionar à Tela de Início**.
O jogo abre em tela cheia, com ícone, como se fosse um app.

## 4. App Android (APK)

```bash
flutter build apk --release
```

O arquivo sai em `build/app/outputs/flutter-apk/app-release.apk`. Mande por WhatsApp e instale.
Se o build reclamar de `minSdkVersion`, abra `android/app/build.gradle.kts` (ou `build.gradle`) e troque `minSdk` para `23`.

## Como jogar

1. **Vira a carta**: aparece uma pergunta cuja resposta é um número.
2. **Dá um chute**: seu chute quer dizer "a resposta é **pelo menos** isso". O primeiro chute é livre.
3. **Sobe ou duvida**: na sua vez, chute mais alto que o último, ou grite **VIAJOU!** se achar que passou da conta.
4. **Revela**: se a resposta for **menor** que o chute, quem chutou leva a carta. Se não, quem gritou leva.
5. **Fim**: quem tiver **mais cartas** é o Grande Viajante. Todo o resto ganha.

Quem leva a carta começa a rodada seguinte. Nas Perguntas da Família, a carta avisa quem escreveu (essa pessoa sabe a resposta!).

## Estrutura

```
lib/
├── main.dart                 # inicialização (Firebase opcional, perguntas, tema)
├── models.dart               # Question, Player, Bid, Reveal, Settings, GameState (+ JSON)
├── logic.dart                # regras do jogo, funções puras e testáveis
├── format.dart               # números no padrão brasileiro
├── theme.dart                # cores, fontes e estilo "adesivo"
├── prefs.dart                # nome, cor e id do aparelho
├── sfx.dart                  # efeitos sonoros
├── data/questions.dart       # carrega o banco de perguntas e as categorias
├── net/room.dart             # sala local e sala online (Firestore com transações)
├── screens/                  # home, sala, lobby, jogo, revelação, fim e formulários
└── widgets/                  # carta 3D, teclado, botões, mascote, céu, confete
assets/
├── questions.json            # as perguntas
└── sfx/*.wav                 # sons gerados por código
test/                         # testes das regras e da formatação
```

Cada sala é um documento em `rooms/{CÓDIGO}` no Firestore. Toda jogada passa por uma
**transação**, então dois celulares apertando ao mesmo tempo não bagunçam o estado.

## Adicionar perguntas

Edite `assets/questions.json`. Cada pergunta é assim:

```json
{ "id": "b999", "c": "bichos", "q": "Quantos corações tem um polvo?", "a": 3, "u": "corações", "f": "Curiosidade que aparece na revelação." }
```

- `c`: categoria (`brasil`, `corpo`, `bichos`, `comida`, `espaco`, `esporte`, `mundo`, `pop`, `diaadia`).
- `a`: resposta (pode ter casas decimais: `13.8`).
- `u`: unidade. Use `"ano"` quando a resposta for um ano (aí ela aparece como 1889, não 1.889).
- O `id` precisa ser único.

Prefira fatos que não mudam com o tempo. Os números foram conferidos com fontes conhecidas, mas vale revisar
os que dependem de medição (por exemplo, distâncias e populações).

## Testes

```bash
flutter test
```

## Problemas comuns

| Problema | Solução |
|---|---|
| "Modo online desligado" | Falta rodar o `flutterfire configure` (passo 2). |
| Erro de permissão ao criar sala | As regras do Firestore não foram publicadas (passo 2.3). |
| Página em branco no GitHub Pages | O `--base-href` precisa ser `/NOME-DO-REPO/`, com as barras. |
| Sem som no iPhone | Toque em qualquer botão primeiro (o Safari só libera áudio depois de um toque) e confira o modo silencioso. |
| `minSdkVersion` no Android | Troque `minSdk` para 23 em `android/app/build.gradle(.kts)`. |

## Licença

MIT
