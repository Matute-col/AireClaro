const { detectFileType } = require('../src/utils/fileType');
const files = require('./helpers/files');

describe('detectFileType (by content, not by name)', () => {
  it.each([
    ['jpeg', files.jpeg(), 'photo', 'image/jpeg'],
    ['png', files.png(), 'photo', 'image/png'],
    ['webp', files.webp(), 'photo', 'image/webp'],
    ['mp4', files.mp4(), 'video', 'video/mp4'],
    ['mov', files.mov(), 'video', 'video/quicktime'],
  ])('accepts %s', (_, buffer, kind, mime) => {
    expect(detectFileType(buffer)).toMatchObject({ kind, mime });
  });

  it('rejects HEIC even though it looks like MP4', () => {
    expect(detectFileType(files.heic())).toBeNull();
  });

  it('rejects text and too-short files', () => {
    expect(detectFileType(files.text())).toBeNull();
    expect(detectFileType(Buffer.from([0xff, 0xd8]))).toBeNull();
  });
});
