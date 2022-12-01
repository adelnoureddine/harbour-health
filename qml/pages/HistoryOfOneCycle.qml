import QtQuick 2.0

import Sailfish.Silica 1.0


Page {

    id: historyOfOneCycle

    property Page historyOfAllCycle

    property string flow

    property string feeling

    property string pain

    property string energy

    property string sleepTime

    property string dateMenstrual


    // The effective value will be restricted by ApplicationWindow.allowedOrientations

    allowedOrientations: Orientation.All


    // To enable PullDownMenu, place our content in a SilicaFlickable

    SilicaFlickable {

        anchors.fill: parent


        // PullDownMenu and PushUpMenu must be declared in SilicaFlickable, SilicaListView or SilicaGridView

        PullDownMenu {


            MenuItem {

                text: qsTr("Modify")

                onClicked: pageStack.animatorPush(Qt.resolvedUrl('./AddTodayInfo.qml'))

            }


            MenuItem {

                text: qsTr("Delete")

                onClicked: pageStack.animatorPush(Qt.resolvedUrl('./HistoryOfAllCycle.qml'))

            }


        }


        // Tell SilicaFlickable the height of its content.

        contentHeight: column.height


        // Place our content in a Column.  The PageHeader is always placed at the top

        // of the page, followed by our content.


        Column {

            id: column

            width: parent.width

            spacing: Theme.paddingLarge


            /* Titre de la page */

            PageHeader {

                title: 'Cycle history' }


            Row {

                id : row6


                Label {

                     id : textResume

                     text: 'Summary of : '

                }

                Label {

                     id : txtDateDay

                     text: dateMenstrual

                }

            }  /* Fin row 6 */


            Row {

                id : row7


                Label {

                     id : textFlow

                     text: 'Flow : '

                }

                Label {

                     id : textFlowApp

                     text: flow

                }

            }  /* Fin row 7 */


            Row {

                id : row8


                Label {

                     id : textfelling

                     text: 'Felling : '

                }

                Label {

                     id : textFellingApp

                     text: feeling

                }

            }  /* Fin row 7 */


            Row {

                id : row9


                Label {

                     id : textPain

                     text: 'Pain : '

                }

                Label {

                     id : textPainApp

                     text: pain

                }

            }  /* Fin row 8 */


            Row {

                id : row10


                Label {

                     id : textEnergy

                     text: 'Energy : '

                }

                Label {

                     id : textAppEnergy

                     text: energy

                }

            }  /* Fin row 9 */


            Row {

                id : row11


                Label {

                     id : textSleepTime

                     text: 'Sleep time : '

                }

                Label {

                     id : textAppSleepTime

                     text: sleepTime

                }

            }  /* Fin row 10 */


            Row {

                id : row12


                Label {

                     id : textCycleTime

                     text: 'Cycle time : '

                }

                Label {

                     id : textAppCycleTime

                     text: ' ------ '

                }

            }  /* Fin row 11 */


            Row {

                id : row13


                Label {

                     id : textPeriodDuration

                     text: 'Period Duration : '

                }

                Label {

                     id : textAppPeriodDuration

                     text: ' ------ '

            }

            }/* Fin row 12 */


        }  /* Fin column */


        Component.onCompleted: {

            historyOfAllCycle=previousPage()

            flow = historyOfAllCycle.flow

            feeling = historyOfAllCycle.feeling

            pain = historyOfAllCycle.pain

            energy =historyOfAllCycle.energy

            sleepTime =historyOfAllCycle.sleepTime

            dateMenstrual =historyOfAllCycle.dateMenstrual

        }




    }

}
