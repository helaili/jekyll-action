it('works for the default branch', () => {
  cy.visit('/jekyll-action/')
  cy.get('#multiple').should('be.visible')
  cy.get('body main div header h1').should('contain', 'Jekyll AsciiDoc Action - Multiple versions')
})

/*
it('works for the default branch on a different path', () => {
  cy.visit('/jekyll-action/current')
  cy.get('#multiple').should('be.visible')
  cy.get('body main div header h1').should('contain', 'Jekyll AsciiDoc Action - Multiple versions')
})
*/
