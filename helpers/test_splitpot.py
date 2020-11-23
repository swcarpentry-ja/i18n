from pytest import raises

from splitpot import extract_filename

def test_extract_filename():
    line = '#: this/is/a/file:43'
    assert extract_filename(line) == "file"
    line = '#: this/is/a/file1.md:43'
    assert extract_filename(line) == "file1.md"

def test_extract_filename_wrong():
    line = '$: this is not a good line'
    with raises(TypeError, match=r'The current line is not one that contains a filename\.'):
        extract_filename(line)
