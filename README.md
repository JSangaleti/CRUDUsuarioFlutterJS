# CRUD de usuário
Com *front-end* em Flutter e *back-end* em JavaScript utilizando Node.js.

## Requisitos

É necessário ter:
- Node.js;
- Google Chrome;
- Flutter;
- Docker;
- Docker Compose.

## Como executar tudo

Primeiro, clone o projeto com `git clone https://github.com/JSangaleti/CRUDUsuarioFlutterJS.git`, acesse a pasta do projeto e abra dois terminais.

Em **um** terminal:
```sh
cd backend
docker compose up -d
npm install
npm run dev
```
E deixe rodando...

Em **outro** terminal:
```sh
cd frontend
flutter pub get
flutter run -d chrome
```
E deixe rodando também...

A partir daí, uma janela do Chrome será executada com a URL da aplicação.
## Funcionalidades

- Cadastrar usuário;
- Listar usuários;
- Editar usuário;
- Excluir usuário.

## [Pasta com *screenshots* da aplicação](./screenshots/)
