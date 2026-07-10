/**
 * lexer.h — MATHLIB5 Lexer
 * Tokenizes source text into tokens for the parser.
 */

#ifndef MATHLIB5_LEXER_H
#define MATHLIB5_LEXER_H

#include <stddef.h>

typedef enum {
    /* Literals */
    TOK_INT, TOK_FLOAT, TOK_STRING, TOK_IDENT,

    /* Keywords */
    TOK_THEOREM, TOK_LEMMA, TOK_DEF, TOK_AXIOM,
    TOK_PROOF, TOK_BY, TOK_END,
    TOK_IF, TOK_THEN, TOK_ELSE, TOK_LET, TOK_IN,
    TOK_FORALL, TOK_EXISTS, TOK_LAMBDA,
    TOK_TRUE, TOK_FALSE, TOK_NOT, TOK_AND, TOK_OR,
    TOK_IMPLIES, TOK_IFF,

    /* Symbols */
    TOK_LPAREN, TOK_RPAREN, TOK_LBRACKET, TOK_RBRACKET,
    TOK_LBRACE, TOK_RBRACE,
    TOK_COLON, TOK_SEMICOLON, TOK_COMMA, TOK_DOT,
    TOK_EQUALS, TOK_NEQ, TOK_LT, TOK_GT, TOK_LE, TOK_GE,
    TOK_PLUS, TOK_MINUS, TOK_STAR, TOK_SLASH, TOK_CARET,
    TOK_ARROW, TOK_DARROW, TOK_PIPE,

    /* Special */
    TOK_EOF, TOK_ERROR,
    TOK_NEWLINE, TOK_COMMENT,
} TokenKind;

typedef struct {
    TokenKind kind;
    const char *start;
    size_t length;
    size_t line;
    size_t column;
} Token;

typedef struct {
    const char *source;
    const char *current;
    size_t line;
    size_t column;
    Token current_token;
} Lexer;

void lexer_init(Lexer *lexer, const char *source);
Token lexer_next(Lexer *lexer);
Token lexer_peek(Lexer *lexer);
const char *token_kind_name(TokenKind kind);

#endif /* MATHLIB5_LEXER_H */
