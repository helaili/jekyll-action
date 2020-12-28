it('works', () => {
  cy.visit('/jekyll-action/')
  cy.get('body main div header h1').should('contain', 'Jekyll AsciiDoc Action - Jekyll & Gem Src')
})