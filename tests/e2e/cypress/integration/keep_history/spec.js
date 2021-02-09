it('works', () => {
  cy.visit('/jekyll-action/')
  cy.get('#jekyll_src').should('be.visible')
  cy.get('body main div header h1').should('contain', 'Jekyll AsciiDoc Action - Keep history')
  cy.get('#env').should('contain', 'production')
})

it('keeps files', () => {
  cy.visit('/jekyll-action/hello.html')
  cy.get('body p').should('contain', 'hello')
})