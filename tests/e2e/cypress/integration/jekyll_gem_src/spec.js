it('works', () => {
  cy.visit('/jekyll-action/')
  cy.get('#jekyll_gem_src').should('be.visible')
  cy.get('body main div header h1').should('contain', 'Jekyll AsciiDoc Action - Jekyll & Gem Src')
  cy.get('#env').should('contain', 'production')
})