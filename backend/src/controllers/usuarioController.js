const pool = require('../config/db');

const listarUsuarios = async (req, res) => {
    try {
        const result = await pool.query('SELECT * FROM usuarios ORDER BY id ASC');
        res.status(200).json(result.rows);
    } catch (error) {
        console.error(error);
        res.status(500).json({ erro: 'Erro ao buscar usuários' });
    }
};

const buscarUsuarioPorId = async (req, res) => {
    const { id } = req.params;

    try {
        const result = await pool.query('SELECT * FROM usuarios WHERE id = $1', [id]);

        if (result.rows.length === 0) {
            return res.status(404).json({ erro: 'Usuário não encontrado' });
        }

        res.status(200).json(result.rows[0]);
    } catch (error) {
        console.error(error);
        res.status(500).json({ erro: 'Erro ao buscar usuário' });
    }
};

const criarUsuario = async (req, res) => {
    const { nome, email } = req.body;

    if (!nome || !email) {
        return res.status(400).json({ erro: 'Nome e e-mail são obrigatórios' });
    }

    try {
        const query = 'INSERT INTO usuarios (nome, email) VALUES ($1, $2) RETURNING *';
        const result = await pool.query(query, [nome, email]);
        res.status(201).json(result.rows[0]);
    } catch (error) {
        console.error(error);

        if (error.code === '23505') {
            return res.status(409).json({ erro: 'E-mail já cadastrado' });
        }

        res.status(500).json({ erro: 'Erro ao criar usuário' });
    }
};

const atualizarUsuario = async (req, res) => {
    const { id } = req.params;
    const { nome, email } = req.body;

    if (!nome || !email) {
        return res.status(400).json({ erro: 'Nome e e-mail são obrigatórios' });
    }

    try {
        const query = `
            UPDATE usuarios
            SET nome = $1, email = $2
            WHERE id = $3
            RETURNING *
        `;
        const result = await pool.query(query, [nome, email, id]);

        if (result.rows.length === 0) {
            return res.status(404).json({ erro: 'Usuário não encontrado' });
        }

        res.status(200).json(result.rows[0]);
    } catch (error) {
        console.error(error);

        if (error.code === '23505') {
            return res.status(409).json({ erro: 'E-mail já cadastrado' });
        }

        res.status(500).json({ erro: 'Erro ao atualizar usuário' });
    }
};

const deletarUsuario = async (req, res) => {
    const { id } = req.params;

    try {
        const result = await pool.query(
            'DELETE FROM usuarios WHERE id = $1 RETURNING *',
            [id]
        );

        if (result.rows.length === 0) {
            return res.status(404).json({ erro: 'Usuário não encontrado' });
        }

        res.status(200).json({ mensagem: 'Usuário removido com sucesso' });
    } catch (error) {
        console.error(error);
        res.status(500).json({ erro: 'Erro ao deletar usuário' });
    }
};

module.exports = {
    listarUsuarios,
    buscarUsuarioPorId,
    criarUsuario,
    atualizarUsuario,
    deletarUsuario
};