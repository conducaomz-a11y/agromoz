<?php
/**
 * Rotas de créditos de IA — appapi/routes/credits.php
 *
 * Tabela necessária (cria uma vez no MySQL):
 *
 * CREATE TABLE IF NOT EXISTS app_credits (
 *   id           INT AUTO_INCREMENT PRIMARY KEY,
 *   user_id      INT NOT NULL,
 *   balance      INT NOT NULL DEFAULT 0,
 *   bonus_given  TINYINT(1) NOT NULL DEFAULT 0,
 *   updated_at   TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
 *   UNIQUE KEY uq_user (user_id),
 *   CONSTRAINT fk_credits_user FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
 * ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
 */

/** GET /credits/balance — saldo atual. Cria linha se não existir (SEM bónus). */
function route_credits_balance(): void {
    $user = require_auth();
    $row  = _credits_row((int)$user['id']);
    json_out(['data' => ['balance' => (int)$row['balance']]]);
}

/** POST /credits/add — adicionar créditos (anúncio ou reembolso). */
function route_credits_add(): void {
    $user   = require_auth();
    $amount = max(1, (int)field('amount', 1));
    $source = (string)field('source', 'ad');

    _credits_ensure((int)$user['id']);
    db()->prepare(
        'UPDATE app_credits SET balance = balance + ? WHERE user_id = ?'
    )->execute([$amount, $user['id']]);

    $row = _credits_row((int)$user['id']);
    json_out(['data' => ['balance' => (int)$row['balance'], 'source' => $source]]);
}

/** POST /credits/spend — debitar créditos para gerar descrição. */
function route_credits_spend(): void {
    $user   = require_auth();
    $amount = max(1, (int)field('amount', 1));

    _credits_ensure((int)$user['id']);
    $row = _credits_row((int)$user['id']);

    if ((int)$row['balance'] < $amount) {
        json_error('Créditos insuficientes.', 422);
    }

    db()->prepare(
        'UPDATE app_credits SET balance = GREATEST(0, balance - ?) WHERE user_id = ?'
    )->execute([$amount, $user['id']]);

    $row = _credits_row((int)$user['id']);
    json_out(['data' => ['balance' => (int)$row['balance']]]);
}

/**
 * POST /credits/claim-bonus — reivindica o crédito bónus de boas-vindas.
 * Só funciona UMA VEZ por conta (bonus_given = 0 → 1).
 * A app chama este endpoint depois do primeiro login bem-sucedido.
 */
function route_credits_claim_bonus(): void {
    $user = require_auth();
    $uid  = (int)$user['id'];

    _credits_ensure($uid);
    $row = _credits_row($uid);

    // Já recebeu o bónus — devolve saldo sem alterar.
    if ((int)$row['bonus_given'] === 1) {
        json_out(['data' => ['balance' => (int)$row['balance'], 'bonus_given' => true]]);
        return;
    }

    // Marca bónus como dado E adiciona 1 crédito — operação atómica.
    db()->prepare(
        'UPDATE app_credits SET balance = balance + 1, bonus_given = 1 WHERE user_id = ? AND bonus_given = 0'
    )->execute([$uid]);

    $row = _credits_row($uid);
    json_out(['data' => ['balance' => (int)$row['balance'], 'bonus_given' => true]]);
}

// ── helpers ───────────────────────────────────────────────────────

/** Garante linha para o utilizador — SEM crédito bónus (balance=0). */
function _credits_ensure(int $userId): void {
    db()->prepare(
        'INSERT IGNORE INTO app_credits (user_id, balance, bonus_given) VALUES (?, 0, 0)'
    )->execute([$userId]);
}

function _credits_row(int $userId): array {
    _credits_ensure($userId);
    $q = db()->prepare('SELECT * FROM app_credits WHERE user_id = ?');
    $q->execute([$userId]);
    return $q->fetch();
}
