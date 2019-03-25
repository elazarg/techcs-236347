from functools import reduce
from typing import Optional, Tuple

from lib.adt.tree import Tree
from lib.parsing.earley.earley import Grammar, Parser, ParseTrees
from lib.parsing.silly import SillyLexer


class LambdaParser(object):
    TOKENS = r"(let|in)(?![\w\d_])   (?P<id>[^\W\d]\w*)   (?P<num>\d+)   [\\.()=]".split()
    GRAMMAR = r"""
    E    ->  \. | let_    |   E1  |  E1'
    E1   ->  @            |   E0
    E1'  ->  @'           |   E0
    E0   ->  id | num     |  ( E )
    \.   ->  \ L . E 
    @    ->  E1 E0
    @'   ->  E1 \.
    L    ->  id L |
    let_ ->  let id = E in E
    """

    def __init__(self):
        self.tokenizer = SillyLexer(self.TOKENS)
        self.grammar = Grammar.from_string(self.GRAMMAR)

    def __call__(self, program_text: str) -> Optional[Tree]:
        tokens = list(self.tokenizer(program_text))

        earley = Parser(grammar=self.grammar, sentence=tokens, debug=False)
        earley.parse()

        if earley.is_valid_sentence():
            trees = ParseTrees(earley)
            assert (len(trees) == 1)
            return self.postprocess(trees.nodes[0])
        else:
            return None

    def postprocess(self, t: Tree) -> Tree:
        if t.root in ['γ', 'E', 'E0', 'E1', "E1'"] and len(t.subtrees) == 1:
            return self.postprocess(t.subtrees[0])
        elif t.root == 'E0' and t.subtrees[0].root == '(':
            return self.postprocess(t.subtrees[1])
        elif t.root == r'\.':
            args = t.subtrees[1].split()
            t = reduce(lambda t, a: Tree('\\', [a, t]), reversed(args), t.subtrees[3])
        elif t.root == "@'":
            t = Tree('@', t.subtrees)
        elif t.root == 'L':
            t = Tree('.', t.split())

        return Tree(t.root, [self.postprocess(s) for s in t.subtrees])


"""
Formats an expression for pretty printing.
Should be called as pretty(e), admitting the default values for `parent` and `follow`;
these values are suitable for the top-level term.
They are used subsequently by recursive calls.
"""


def pretty(expr: Tree, parent: Tuple[str, int] = ('.', 0), follow: str = '') -> str:
    if expr.root in ['id', 'num']: return expr.subtrees[0].root
    if expr.root == '\\':
        tmpl = r"\%s. %s"
        if parent == ('@', 0) or parent[0] == follow == '@': tmpl = "(%s)" % tmpl
    elif expr.root == '@':
        tmpl = "%s %s"
        if parent == ('@', 1): tmpl = "(%s)" % tmpl
    else:
        return str(expr)

    n = len(expr.subtrees)
    return tmpl % tuple(pretty(s, (expr.root, i), expr.root if i < n - 1 else follow)
                        for i, s in enumerate(expr.subtrees))


def dot_print(expr: Tree) -> None:
    from graphviz import Source
    from os import linesep
    from tempfile import NamedTemporaryFile
    temp = """digraph G{
edge [dir=forward]

"""
    nodes = {id(n): (i, n) for (i, n) in enumerate(expr.nodes)}
    edges = {(nodes[id(n)][0], nodes[id(s)][0]) for n in expr.nodes for s in n.subtrees}

    def translate_backslash(x): return str(x).replace("\\", "\\\\")

    nodes_string = linesep.join([f"{i[0]} [label=\"{translate_backslash(i[1].root)}\"]" for n, i in nodes.items()])
    edges_string = linesep.join([f"{n} -> {s}" for (n, s) in edges])
    tmp_file = NamedTemporaryFile(delete=False)
    s = Source(temp + nodes_string + linesep + edges_string + linesep + "}", filename=tmp_file.name)
    s.view(filename=tmp_file.name)


if __name__ == '__main__':
    expr = LambdaParser()(r"\x. x \z g. y 6")
    expr2 = LambdaParser()(r"\x. x \z g. y 6 5 4")
    if expr:
        print(">> Valid expression.")
        print(expr)
        # dot_print(expr)
    else:
        print(">> Invalid expression.")
