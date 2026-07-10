/**
 * lexer.c — MATHLIB5 Lexer Implementation
 */

#include "lexer.h"
#include <ctype.h>
#include <string.h>

void lexer_init(Lexer *lexer, const char *source) {
    lexer->source = source;
    lexer->current = source;
    lexer->line = 1;
    lexer->column = 1;
}

static char advance(Lexer *lexer) {
    char c = *lexer->current++;
    if (c == '\n') { lexer->line++; lexer->column = 1; }
    else { lexer->column++; }
    return c;
}

static char peek(Lexer *lexer) { return *lexer->current; }

static int match(Lexer *lexer, char expected) {
    if (*lexer->current == expected) { advance(lexer); return 1; }
    return 0;
}

static void skip_whitespace(Lexer *lexer) {
    for (;;) {
        char c = peek(lexer);
        if (c == ' ' || c == '\t' || c == '\r') advance(lexer);
        else if (c == '\n') advance(lexer);
        else if (c == '-' && lexer->current[1] == '-') {
            while (peek(lexer) != '\n' && peek(lexer) != '\0') advance(lexer);
        }
        else break;
    }
}

static Token make_token(Lexer *lexer, TokenKind kind, const char *start, size_t len) {
    Token t = { kind, start, len, lexer->line, lexer->column };
    return t;
}

static TokenKind check_keyword(const char *start, size_t len) {
    struct { const char *word; size_t len; TokenKind kind; } keywords[] = {
        {"theorem", 7, TOK_THEOREM}, {"lemma", 5, TOK_LEMMA},
        {"def", 3, TOK_DEF}, {"axiom", 5, TOK_AXIOM},
        {"proof", 5, TOK_PROOF}, {"by", 2, TOK_BY}, {"end", 3, TOK_END},
        {"if", 2, TOK_IF}, {"then", 4, TOK_THEN}, {"else", 4, TOK_ELSE},
        {"let", 3, TOK_LET}, {"in", 2, TOK_IN},
        {"forall", 6, TOK_FORALL}, {"exists", 6, TOK_EXISTS},
        {"fun", 3, TOK_LAMBDA}, {"λ", 1, TOK_LAMBDA},
        {"true", 4, TOK_TRUE}, {"false", 5, TOK_FALSE},
        {"not", 3, TOK_NOT}, {"and", 3, TOK_AND}, {"or", 2, TOK_OR},
        {"implies", 7, TOK_IMPLIES}, {"iff", 3, TOK_IFF},
    };
    for (int i = 0; i < (int)(sizeof(keywords)/sizeof(keywords[0])); i++) {
        if (len == keywords[i].len && memcmp(start, keywords[i].word, len) == 0)
            return keywords[i].kind;
    }
    return TOK_IDENT;
}

Token lexer_next(Lexer *lexer) {
    skip_whitespace(lexer);
    const char *start = lexer->current;

    if (*lexer->current == '\0')
        return make_token(lexer, TOK_EOF, start, 0);

    char c = advance(lexer);

    /* Identifiers and keywords */
    if (isalpha(c) || c == '_') {
        while (isalnum(peek(lexer)) || peek(lexer) == '_') advance(lexer);
        size_t len = lexer->current - start;
        return make_token(lexer, check_keyword(start, len), start, len);
    }

    /* Numbers */
    if (isdigit(c)) {
        while (isdigit(peek(lexer))) advance(lexer);
        if (peek(lexer) == '.' && isdigit(lexer->current[1])) {
            advance(lexer);
            while (isdigit(peek(lexer))) advance(lexer);
        }
        return make_token(lexer, TOK_INT, start, lexer->current - start);
    }

    /* Symbols */
    switch (c) {
    case '(': return make_token(lexer, TOK_LPAREN, start, 1);
    case ')': return make_token(lexer, TOK_RPAREN, start, 1);
    case '[': return make_token(lexer, TOK_LBRACKET, start, 1);
    case ']': return make_token(lexer, TOK_RBRACKET, start, 1);
    case '{': return make_token(lexer, TOK_LBRACE, start, 1);
    case '}': return make_token(lexer, TOK_RBRACE, start, 1);
    case ':': return make_token(lexer, match(lexer, '=') ? TOK_EQUALS : TOK_COLON, start, lexer->current - start);
    case ';': return make_token(lexer, TOK_SEMICOLON, start, 1);
    case ',': return make_token(lexer, TOK_COMMA, start, 1);
    case '.': return make_token(lexer, TOK_DOT, start, 1);
    case '+': return make_token(lexer, TOK_PLUS, start, 1);
    case '-': return make_token(lexer, match(lexer, '>') ? TOK_ARROW : TOK_MINUS, start, lexer->current - start);
    case '*': return make_token(lexer, TOK_STAR, start, 1);
    case '/': return make_token(lexer, TOK_SLASH, start, 1);
    case '^': return make_token(lexer, TOK_CARET, start, 1);
    case '=': return make_token(lexer, match(lexer, '=') ? TOK_EQUALS : TOK_EQUALS, start, lexer->current - start);
    case '<': return make_token(lexer, match(lexer, '=') ? TOK_LE : TOK_LT, start, lexer->current - start);
    case '>': return make_token(lexer, match(lexer, '=') ? TOK_GE : TOK_GT, start, lexer->current - start);
    case '|': return make_token(lexer, TOK_PIPE, start, 1);
    case '!': return make_token(lexer, match(lexer, '=') ? TOK_NEQ : TOK_ERROR, start, lexer->current - start);
    }

    return make_token(lexer, TOK_ERROR, start, 1);
}

Token lexer_peek(Lexer *lexer) {
    Lexer tmp = *lexer;
    Token t = lexer_next(lexer);
    *lexer = tmp;
    return t;
}

const char *token_kind_name(TokenKind kind) {
    switch (kind) {
    case TOK_INT: return "INT";
    case TOK_FLOAT: return "FLOAT";
    case TOK_STRING: return "STRING";
    case TOK_IDENT: return "IDENT";
    case TOK_THEOREM: return "theorem";
    case TOK_LEMMA: return "lemma";
    case TOK_DEF: return "def";
    case TOK_AXIOM: return "axiom";
    case TOK_PROOF: return "proof";
    case TOK_BY: return "by";
    case TOK_END: return "end";
    case TOK_IF: return "if";
    case TOK_THEN: return "then";
    case TOK_ELSE: return "else";
    case TOK_LET: return "let";
    case TOK_IN: return "in";
    case TOK_FORALL: return "forall";
    case TOK_EXISTS: return "exists";
    case TOK_LAMBDA: return "fun";
    case TOK_TRUE: return "true";
    case TOK_FALSE: return "false";
    case TOK_NOT: return "not";
    case TOK_AND: return "and";
    case TOK_OR: return "or";
    case TOK_IMPLIES: return "implies";
    case TOK_IFF: return "iff";
    case TOK_LPAREN: return "(";
    case TOK_RPAREN: return ")";
    case TOK_LBRACKET: return "[";
    case TOK_RBRACKET: return "]";
    case TOK_LBRACE: return "{";
    case TOK_RBRACE: return "}";
    case TOK_COLON: return ":";
    case TOK_SEMICOLON: return ";";
    case TOK_COMMA: return ",";
    case TOK_DOT: return ".";
    case TOK_EQUALS: return "=";
    case TOK_NEQ: return "!=";
    case TOK_LT: return "<";
    case TOK_GT: return ">";
    case TOK_LE: return "<=";
    case TOK_GE: return ">=";
    case TOK_PLUS: return "+";
    case TOK_MINUS: return "-";
    case TOK_STAR: return "*";
    case TOK_SLASH: return "/";
    case TOK_CARET: return "^";
    case TOK_ARROW: return "->";
    case TOK_DARROW: return "=>";
    case TOK_PIPE: return "|";
    case TOK_EOF: return "EOF";
    case TOK_ERROR: return "ERROR";
    case TOK_NEWLINE: return "NEWLINE";
    case TOK_COMMENT: return "COMMENT";
    }
    return "?";
}
