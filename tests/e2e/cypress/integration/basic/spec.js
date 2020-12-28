it('works', () => {
  cy.visit('/jekyll-action/')
  cy.get('#basic').should('be.visible')
  cy.get('body main div header h1').should('contain', 'Jekyll AsciiDoc Action - Basic')
  cy.get('#env').should('contain', 'development')
})
